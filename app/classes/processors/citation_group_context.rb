module Processors
  class CitationGroupContext < Base
    include Helpers

    def process
      citation_groups.each do |group|
        group[:context] = citation_context(group[:nodes])
      end
    end

    def self.dependencies
      [CitationGroups]
    end

    CITATION_CONTEXT_LENGTH = 60

    protected

    def citation_context(nodes)
      context_node  = XmlUtilities.nearest(nodes.first, ['p', 'sec', 'body']) || body
      citation_text = XmlUtilities.text_between(nodes.first, nodes.last)

      text_before = XmlUtilities.text_before(context_node, nodes.first)
      text_after  = XmlUtilities.text_after(context_node, nodes.last)

      length_before = (CITATION_CONTEXT_LENGTH - citation_text.length) / 2
      text_before = text_before.truncate_beginning(length_before, separator:/\s+/, omission:"\u2026")

      length_after = CITATION_CONTEXT_LENGTH - citation_text.length - text_before.length
      text_after = text_after.truncate(length_after, separator:/\s+/, omission:"\u2026")

      # Recalculate before in case the citation turned out to be near the end of the text
      length_before2 = CITATION_CONTEXT_LENGTH - citation_text.length - text_after.length
      if length_before2 > length_before
        text_before = text_before.truncate_beginning(length_before2, separator:/\s+/, omission:"\u2026")
      end

      "#{text_before}#{citation_text}#{text_after}"
    end

  end
end