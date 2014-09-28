# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'uri'

module Processors
  class ReferencesInfoFromPubmed < Base
    include Helpers

    def process
      references = references_without_bib_info(:pmid)
      fill_info_for_references(references) if references.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf http://www.ncbi.nlm.nih.gov/books/NBK25497/
    #    This table is also useful http://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.chapter4_table1/?report=objectonly
    #    We could also use the altimetrics API

    API_URL = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml'

    def fill_info_for_references(references)
      reference_ids = references.map { |ref| ref[:uri]}

      results = fetch_results_for_ids(reference_ids)

      results.css('PubmedArticle').each do |result|
        info = convert_result_to_info(result)
        next unless info.present?

        pmid = info[:PMID]
        next unless pmid
        ref = reference_by_uri(:pmid, pmid)

        next unless ref
        ref[:bibliographic] ||= {}
        ref[:bibliographic].merge!(info)
      end

    end

    def fetch_results_for_ids(ids)
      data  = 'id=' + ids.join(',')
      xml   = HttpUtilities.post(API_URL, data,
                                 'Content-Type' => Mime::URL_ENCODED_FORM, 'Accept' => Mime::XML  )
      Nokogiri::XML(xml)
    end

    def convert_result_to_info(result)
      @result = result

      {
          bib_source:          'NIH',
          PMID:                value('PubmedData ArticleIdList *[IdType=pubmed]'), # || value('MedlineCitation > PMID'),
          PMCID:               value('PubmedData ArticleIdList *[IdType=pmc]'),
          DOI:                 value('PubmedData ArticleIdList *[IdType=doi]'),
          title:               xml('MedlineCitation ArticleTitle'),
          # subtitle:
          issued:              date_value('PubmedData PubMedPubDate[PubStatus=pubmed]'),
          # publisher:
          subject:             subjects,
          author:              authors,
          page:                value('MedlineCitation Pagination MedlinePgn'),
          :'container-type'=>  value('PublicationTypeList PublicationType'),
          :'container-title'=> value('MedlineCitation Journal Title'),
          volume:              value('MedlineCitation Journal Volume'),
          issue:               value('MedlineCitation Journal Issue'),
          abstract:            xml('MedlineCitation AbstractText'),
      }.compact
    end

    def value(selector)
      node = @result.at_css(selector)
      node && node.text.presence
    end

    def xml(selector)
      node = @result.at_css(selector)
      XmlUtilities.jats2html(node)
    end

    def date_value(selector)
      node = @result.at_css(selector)
      return nil unless node.present?
      [[ node.at_css('Year').text.to_i, node.at_css('Month').text.to_i, node.at_css('Day').text.to_i ]]
    end

    def subjects
      nodes = @result.css('MedlineCitation MeshHeadingList MeshHeading')
      nodes.map { |node| subject_for(node) }.compact.presence
    end

    def subject_for(node)
      node.css('*').map{ |n| n.text }.join(' - ')
    end

    def authors
      nodes = @result.css('MedlineCitation AuthorList Author')
      nodes.map { |node| author_for(node) }.compact.presence
    end

    def author_for(node)
      author = {
          famiy:       node.at_css('LastName').try(:text),
          given:       node.at_css('ForeName').try(:text),
          initials:    node.at_css('Initials').try(:text),
          suffix:      node.at_css('Suffix').try(:text),
          affiliation: node.at_css('Affiliation').try(:text),
          literal:     node.at_css('CollectiveName').try(:text),
      }

      # Extract email
      if !author[:email] && author[:affiliation]
        email = author[:affiliation].split.last
        if email =~ EMAIL_REGEX
          author[:email] = email
          author[:affiliation] = author[:affiliation][0..-email.length-1].rstrip
        end
      end

      author.compact.presence
    end

  end

end
