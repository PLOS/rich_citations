module Plos
  class PaperDatabase

    attr_reader :results

    def self.analyze!(search_query, limit=500)
      Rails.logger.info("Searching for #{search_query.inspect}")
      matching = Plos::Api.search(search_query, query_type:"subject", rows:limit)
      Rails.logger.info("Found #{matching.count} results")
      matching_dois = matching.map { |r| r['id'] }

      database = self.new
      database.results[:match_count] = matching.count
      database.results[:matches] = matching_dois

      matching_dois.each do |doi|
        Rails.logger.info("Fetching #{doi} ...")
        xml = Plos::Api.document( doi )
        Rails.logger.info("Parsing #{doi} ...")
        parser = Plos::PaperParser.new(xml)
        database.add_paper(doi, parser.references)
      end
      Rails.logger.info("Completed Analysis")

      database.results
    end

    def initialize
      @results = {  }
    end

    def add_paper(paper_doi, references)
      @results[:citations] ||= {}

      references.each do |ref_num, ref|
        ref_doi = ref[:doi]
        next unless ref_doi

        info = (@results[:citations][ ref_doi ] ||= {
            :intra_paper_mentions => [],
            :median_co_citations  => [],
            :citations            =>  0,
            :co_citation_counts   => {},
        })

        # info[:id]                  ||= id
        info[:citations]            += 1
        info[:intra_paper_mentions] << ref[:citation_count]
        info[:median_co_citations]  << ref[:median_co_citations]

        if ref[:zero_mentions]
          info[:zero_mentions] ||= []
          info[:zero_mentions] << paper_doi
        end

        if ref[:citation_groups]
          co_citation_counts = info[:co_citation_counts]

          ref[:citation_groups].flatten.each do |co_citation_num|
            if co_citation_num != ref_num
              co_citation_doi = references[co_citation_num][:doi] || 'No-DOI'
              co_citation_counts[co_citation_doi] = co_citation_counts[co_citation_doi].to_i + 1
            end
          end
        end
      end

      @recalculate = true
    end

    def results
      if @recalculate
        @results[:citations].each do |k, info|
          info[:median_ipms ] = info[:intra_paper_mentions].median if info[:intra_paper_mentions]
          info[:median_miccs] = info[:median_co_citations].median  if info[:median_co_citations]
        end
        @recalculate = false
      end

      @results
    end

  end
end