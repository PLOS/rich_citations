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

require 'id/arxiv'

module IdentifierResolvers
  class ArxivFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node)
        set_result(id, info)
      }
    end

    private

    def extract_info(node)
      # Try and extract the doi from the nodes
      # There are lots of corner cases here. This is just a start
      is_arxiv = /arxiv/i =~ node.node.at_css('source').try(:text)
      if is_arxiv
        id = id || Id::Arxiv.id( node.node.at_css('volume').try(:text))
        id = id || Id::Arxiv.id( node.node.at_css('fpage').try(:text))
        id = id || Id::Arxiv.id( node.node.at_css('volume').try(:text).to_s + '.' + node.node.at_css('fpage').try(:text).to_s)
      end

      # Try and extract the link from pure XML
      id = id || Id::Arxiv.extract(node.node.to_xml)

      # Try and extract the DOI from the pure text
      id = id || Id::Arxiv.extract(node.text)

      return nil unless id.present?
      {
          uri_source:  :ref,
          uri:         id,
          uri_type:    :arxiv,
      }
    end

  end
end
