# Add sections node

module Processors
  class ReferencesMentionCount < Base
    include Helpers

    def process
      add_citation_counts
    end

    def self.dependencies
      [ References, CitationGroups ]
    end

    protected

    # The number of times each reference is cited in the paper
    # aka ipm_dictionary
    def add_citation_counts
      all_citations = citation_groups.map{|g| g[:references] }.flatten
      all_citations.group_by {|n| n }.each do |num, references|
        reference_by_number(num)[:mentions] = references.count
      end
    end

  end
end