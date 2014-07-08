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

    CITATION_CONTEXT_WORDS_BEFORE = 20
    CITATION_CONTEXT_WORDS_AFTER  = 10

    protected

    ELLIPSES = "\u2026"

    def citation_context(nodes)
      context_node  = XmlUtilities.nearest(nodes.first, ['p', 'sec', 'body']) || body
      citation_text = XmlUtilities.text_between(nodes.first, nodes.last)

      text_before = XmlUtilities.text_before(context_node, nodes.first)
      text_before, ellipses_before = text_before.word_truncate_beginning(CITATION_CONTEXT_WORDS_BEFORE)
      ellipses_before = ellipses_before ? ELLIPSES : nil

      text_after  = XmlUtilities.text_after(context_node, nodes.last)
      text_after, ellipses_after  = text_after.word_truncate_ending(CITATION_CONTEXT_WORDS_AFTER, )
      ellipses_after = ellipses_after ? ELLIPSES : nil

      {
          ellipses_before: ellipses_before,
          text_before:     text_before.presence,
          citation:        citation_text.presence,
          text_after:      text_after.presence,
          ellipses_after:  ellipses_after,
          quote:           "#{ellipses_before}#{text_before}#{citation_text}#{text_after}#{ellipses_after}",
      }.compact
    end

  end
end