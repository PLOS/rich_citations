# Add sections node

module Processors
  class ReferencesMedianCoCitations < Base
    include Helpers

    def process
      references.each do |_, info|
        info[:median_co_citations] = median_co_citations(info)
      end
    end

    def self.dependencies
      [ ReferencesCitedGroups ]
    end

    protected

    # MICC = median in-line co-citations
    # aka micc_dictionary
    def median_co_citations(ref_info)
      cited_groups = ref_info[:citation_groups]

      if cited_groups.present?
        cocite_counts = cited_groups.map { |g| g[:count] - 1 }
        cocite_counts.median

      else
        nil

      end

    end

  end
end