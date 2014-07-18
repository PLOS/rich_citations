require 'uri'

module Processors
  class ReferencesInfoFromPubmed < Base
    include Helpers

    def process
      # Process in groups since IDs have to fit in a URL
      references_without_info.each_slice(20) do |references|
        fill_info_for_references(references)
      end
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf http://www.ncbi.nlm.nih.gov/books/NBK25497/
    #    This table is also useful http://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.chapter4_table1/?report=objectonly
    #    We could also use the altimetrics API
    #    Since ids are in the url we cannot do more than a few at a time

    API_URL = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id='

    def references_without_info
      references_for_type(:pmid).reject { |ref| ref[:info] && ref[:info][:source] }
    end

    def fill_info_for_references(references)
      reference_ids = references.map { |ref| ref[:id]}

      results = fetch_results_for_ids(reference_ids)

      results.css('PubmedArticle').each do |result|
        info = convert_result_to_info(result)
        next unless info.present?

        pmid = info[:PMID]
        next unless pmid
        ref = reference_by_identifier(:pmid, pmid)

        next unless ref
        ref[:info] ||= {}
        ref[:info].merge!(info)
      end

    end

    def fetch_results_for_ids(ids)
      url    = API_URL + ids.join(',')
      xml   = HttpUtilities.get(url, :xml)
      Nokogiri::XML(xml)
    end

    def convert_result_to_info(result)
      @result = result

      {
          source:              'NIH',
          PMID:                value('PubmedData ArticleIdList *[IdType=pubmed]'), # || value('MedlineCitation > PMID'),
          PMCID:               value('PubmedData ArticleIdList *[IdType=pmc]'),
          DOI:                 value('PubmedData ArticleIdList *[IdType=doi]'),
          title:               value('MedlineCitation ArticleTitle'),
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
          abstract:            value('MedlineCitation AbstractText'),
      }.compact
    end

    def value(selector)
      node = @result.at_css(selector)
      node && node.text.presence
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
