module Plos
  class PaperDatabase

    attr_reader :results

    def initialize
      @results = {}
    end

    def add_paper(paper_doi, references)

      references.each do |num, ref|
        ref_doi = ref[:doi]
        next unless ref_doi

        info = (@results[ ref_doi ] ||= {
            :intra_paper_mentions => [],
            :median_co_citations  => [],
            :citations            =>  0,
        })

        # info[:id]                  ||= id
        info[:citations]            += 1
        info[:intra_paper_mentions] << ref[:citation_count]
        info[:median_co_citations]  << ref[:median_co_citations]

        if ref[:zero_mentions]
          info[:zero_mentions] ||= []
          info[:zero_mentions] << paper_doi
        end
      end

    end

    def results
      unless @completed
        @results.each do |k, info|
          info[:median_ipms ] = info[:intra_paper_mentions].median if info[:intra_paper_mentions]
          info[:median_miccs] = info[:median_co_citations].median  if info[:median_co_citations]
        end
      end

      @results
    end

  end
end