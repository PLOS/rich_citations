# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
      }.compact
    end

  end
end
