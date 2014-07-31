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
  class Authors < Base

    def process
      result[:paper] ||= {}
      # result[:paper][:affiliations] = affiliations
      result[:paper][:author] = authors
    end

    protected

    def authors
      author_nodes.map do |node|
        {
            given:       author_given_name(node),
            family:      author_family_name(node),
            literal:     author_literal_name(node),
            email:       author_email(node),
            affiliation: author_affiliation(node),
        }.compact
      end
    end

    def author_given_name(node)
      node.css('given-names').text.strip.presence
    end

    def author_family_name(node)
      node.css('surname').text.strip.presence
    end

    def author_literal_name(node)
      node.css('literal').text.strip.presence
    end

    def author_email(node)
      xref = node.css('xref[ref-type=corresp]')

      if xref.present?
        rid = xref.first['rid']
        corresp = xml.css("article-meta corresp[id=#{rid}]")
        email = corresp.css('email')

        if email.present?
          email.text
        elsif corresp.present?
          corresp.text
        end
      end
    end

    def author_affiliation(node)
      xref = node.css('xref[ref-type=aff]')

      if xref.present?
        rid = xref.first['rid']
        affiliations[rid]
      end
    end

    def affiliations
      @affilitations ||= affiliate_nodes.map do |node|
        text_node = node.css('addr-line')
        text_node = node if text_node.empty?
        [node['id'], text_node.text]
      end.to_h
    end

    def affiliate_nodes
      xml.css('article-meta aff')
    end

    def author_nodes
      nodes = xml.css('article-meta contrib[contrib-type=author]')
    end

  end
end
