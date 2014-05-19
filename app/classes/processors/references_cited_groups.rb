# Add sections node

module Processors
  class ReferencesCitedGroups < Base
    include Helpers

    def process
      references.each do |ref_num, info|
        info[:citation_groups] = cited_groups(ref_num)
      end
    end

    def self.dependencies
      [ References, CitationGroups ]
    end

    protected

    def cited_groups(ref_num)
      groups = citation_groups.select { |g| g[:references].include?(ref_num) }
      groups.present? ? groups : nil
    end

  end
end