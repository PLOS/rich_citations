module Plos
  class Paper

    attr_accessor :doi,
                  :intra_paper_mentions,
                  :median_co_citations,
                  :zero_mentions

    def initialize
      @intra_paper_mentions = []
      @median_co_citations  = []
    end

    def citations
      @median_co_citations.count
    end

    def median_ipm
      @median_ipm ||= @intra_paper_mentions.median
    end

    def median_micc
      @median_micc ||= @median_co_citations.median
    end

  end
end