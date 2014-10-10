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

module IdentifierResolvers
  class DoiFromPlosHtml < Base

    def resolve
      unresolved_references.each do |id, data|
        ref_node = node_for_ref_id(id)
        next unless ref_node.present?

        links_node = ref_node.css('> ul.find')
        next unless links_node.present?

        doi = Id::Doi.extract(links_node.first['data-doi'])

        info  = info_for_doi(doi)
        set_result(id, info) if info
      end
    end

    private

    def reference_nodes
      @reference_nodes ||= begin
        response = HttpUtilities.get(root.citing_uri)
        html     = Nokogiri::HTML::Document.parse(response)
        html.css('ol.references li')
      end
    end

    def node_for_ref_id(ref_id)
      reference_nodes.find do |n|
        n.xpath("./a[@id = '#{ref_id}']").present?
      end
    end

    def info_for_doi(doi)
      doi = Id::Doi.extract( doi )
      return nil unless doi.present?

      {
        uri_source:   :plos_html,
        uri_type:     :doi,
        uri:          "http://dx.doi.org/#{doi}"
      }
    end

  end
end
