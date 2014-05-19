module Processors
  class CitationGroupPosition < Base
    include Helpers

    def process
      citation_groups.each do |group|
        group[:word_position] = word_position(group[:nodes])
      end
    end

    def self.dependencies
      [CitationGroups]
    end

    protected

    def word_position(nodes)
      XmlUtilities.text_before(body, nodes.first).word_count + 1
    end

  end
end