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
  class ReferencesInfoFromPmc < Base
    include Helpers

    def process
      # Process in groups since IDs have to fit in a URL
      references = references_without_bib_info(:pmcid)
      fill_info_for_references(references) if references.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf http://www.ncbi.nlm.nih.gov/books/NBK25497/
    #    This table is also useful http://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.chapter4_table1/?report=objectonly
    #    We could also use the altimetrics API

    API_URL = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&retmode=xml'

    def fill_info_for_references(references)
      reference_ids = references.map { |ref| ref[:uri]}

      results = fetch_results_for_ids(reference_ids)

      results.css('article').each do |result|
        info = convert_result_to_info(result)
        next unless info.present?

        pmcid = Id::Pmcid.normalize( info[:PMCID] )
        next unless pmcid
        ref = reference_by_uri(:pmcid, pmcid)

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
          PMCID:               Id::Pmcid.normalize( value('article-meta article-id[pub-id-type=pmc]') ),
          PMID:                value('article-meta article-id[pub-id-type=pmid]'),
          DOI:                 value('article-meta article-id[pub-id-type=doi]'),
          title:               xml('article-meta article-title'),
          # # subtitle:
          issued:              date_value('article-meta pub-date[pub-type=epub]') || date_value('article-meta pub-date[pub-type=ppub]'),
          publisher:           value('journal-meta publisher-name'),
          subject:             subjects,
          author:              authors,
          page:                pages,
          # :'container-type'
          :'container-title'=> value('journal-meta journal-title'),
          volume:              value('article-meta volume'),
          issue:               value('article-meta issue'),
          abstract:            xml('article-meta abstract').try(:strip),
      }.compact
    end

    def value(selector)
      node = @result.at_css(selector)
      node && node.text.presence
    end

    def xml(selector)
      node = @result.at_css(selector)
      XmlUtilities.jatsdoc2html(node)
    end

    def date_value(selector)
      node = @result.at_css(selector)
      return nil unless node.present?

      [
        [
          node.at_css('year').text.to_i,
          node.at_css('month').try{|t|t.text.to_i},
          node.at_css('day').try{|t|t.text.to_i},
        ].compact
      ]
    end

    def pages
      from = value('article-meta fpage')
      to   = value('article-meta lpage')
      if to && from != to
        "#{from}-#{to}"
      elsif from
        from
      else
        nil
      end
    end

    # In this result the subjects are a hierarchical list
    def subjects(list=[], root=@result.at_css('article-meta article-categories'), prefix = nil)
      return unless root
      subj_node = root.at_css('> subject')

      subj_text = subj_node && subj_node.text

      if subj_text.present?
        prefix = [prefix, subj_text].compact.join(" - ")
        list << prefix
      end

      root.css('> subj-group').each do |node|
        subjects(list, node, prefix)
      end

      list.presence
    end

    def authors
      nodes = @result.css('article-meta contrib-group contrib[contrib-type=author]')
      nodes.map { |node| author_for(node) }.compact.presence
    end

    # Same as Processors::Authors.author
    def author_for(node)
      {
          given:       node.css('given-names').text.strip.presence,
          family:      node.css('surname').text.strip.presence,
          literal:     node.css('literal').text.strip.presence,
          email:       author_email(node),
          affiliation: author_affiliation(node),
      }.compact.presence
    end

    def author_affiliation(node)
      xref = node.at_css('xref[ref-type=aff]')

      if xref.present?
        rid = xref['rid']
        aff = @result.at_css("article-meta contrib-group aff[id=#{rid}]").xpath("text()")
        aff && aff.text.strip.presence
      end
    end

    def author_email(node)
      xref = node.at_css('xref[ref-type=corresp]')

      if xref.present?
        rid = xref['rid']
        email = @result.at_css("article-meta corresp[id=#{rid}] email")
        email && email.text.strip
      end
    end

  end

end
