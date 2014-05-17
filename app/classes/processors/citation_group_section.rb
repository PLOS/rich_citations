module Processors
  class CitationGroupSection < Base
    include Helpers

    def process
      citation_groups.each do |group|
        group[:section] = section_title(group[:nodes])
      end
    end

    def self.dependencies
      [CitationGroups]
    end

    protected

    # Get the outermost section title
    def section_title(nodes)
      node = nodes.first
      title = nil

      while node && defined?(node.parent)
        if node.name == 'sec'
          title_node = node.css('> title')
          title = title_node.text if title_node.present? && title_node.text
        end

        node = node.parent
      end

      title || '[Unknown]'
    end

  end
end