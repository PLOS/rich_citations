# Add sections node

module Processors
  class ReferencesCitedGroups < Base
    include Helpers

    def process
      references.each do |id, info|
        info[:citation_groups] = cited_groups(id)
      end
    end

    def self.dependencies
      [ References, CitationGroups ]
    end

    protected

    def cited_groups(id)
      groups = citation_groups.select { |g| g[:references].include?(id) }
      groups.present? ? groups : nil
    end

  end
end