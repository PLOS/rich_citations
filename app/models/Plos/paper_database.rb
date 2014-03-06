module Plos
  class PaperDatabase

    attr_reader :results

    def self.analyze!(search_query, limit=500)
      Rails.logger.info("Searching for #{search_query.inspect}")
      matching = Plos::Api.search(search_query, query_type:"subject", rows:limit)
      Rails.logger.info("Found #{matching.count} results")
      matching_dois = matching.map { |r| r['id'] }

      database = self.new

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
      @results = {
          match_count: 0,
          matches:     [],
      }
    end

    def add_paper(paper_doi, references)
      @results[:match_count] += 1
      @results[:matches] << paper_doi

      @results[:citations] ||= {}

      references.each do |ref_num, ref|
        ref_num = ref_num.to_i
        ref_doi = ref[:doi]
        next unless ref_doi

        info = doi_info(ref_doi)

        # info[:id]                  ||= id
        info[:citations]            += 1
        info[:intra_paper_mentions] << ref[:citation_count]
        info[:median_co_citations]  << ref[:median_co_citations]

        if ref[:zero_mentions]
          info[:zero_mentions] ||= []
          info[:zero_mentions] << paper_doi
        end

        add_citation_groups(ref_num, info, ref, references)
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

    private

    def doi_info(doi)
      @results[:citations][ doi ] ||= {
        :intra_paper_mentions => [],
        :median_co_citations  => [],
        :citations            =>  0,
        :sections             => {},
        :co_citation_counts   => {},
      }
    end

    def add_citation_groups(ref_num, info, ref, all_references)
      return unless ref[:citation_groups]

      sections = info[:sections]
      co_citation_counts = info[:co_citation_counts]

      ref[:citation_groups].each do |group|

        # Aggregate section counts
        section = group[:section]
        sections[section] = sections[section].to_i + 1

        # Aggregate co-citation counts
        group[:references].each do |co_citation_num|
          if co_citation_num != ref_num
            cc_ref = all_references[co_citation_num] || all_references[co_citation_num.to_s]
            co_citation_doi = cc_ref[:doi] || 'No-DOI'
            co_citation_counts[co_citation_doi] = co_citation_counts[co_citation_doi].to_i + 1
          end
        end

      end
    end

  end
end