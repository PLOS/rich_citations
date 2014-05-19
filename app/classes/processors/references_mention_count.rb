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
      all_citations.group_by {|id| id }.each do |id, references|
        reference_by_id(id)[:mentions] = references.count
      end
    end

  end
end