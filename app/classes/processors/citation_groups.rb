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
  class CitationGroups < Base
    include Helpers

    # A citation group is all of the papers that are cited together at a certain point in the paper
    # -- the bare stuff of inline co-citations.
    # So, for example, a citation group might simply be [1], or it could be [2]-[10], or even
    # [11], [13]-[17], [21].

    def process
      result[:citation_groups] = citation_groups
    end

    def cleanup
      result[:citation_groups].each do |group|
        group.delete(:nodes)
        group.compact!
      end
    end

    def self.dependencies
      [References]
    end

    ####################################################do
    # Callbacks for CitationGrouper

    def number_for_citation_node(xref_node)
      refid = xref_node['rid']
      ref   = reference_by_id(refid)
      ref && ref[:number]
    end

    def reference_id_for_number(number)
      ref = reference_by_number(number)
      ref && ref[:ref]
    end

    protected

    # Returns an array of arrays containing reference numbers
    def citation_groups
      grouper = CitationGrouper.new(self)

      citation_nodes.each do |citation|
        grouper.add_citation(citation)
      end

      grouper.groups
    end

    def citation_nodes
      @citation_nodes ||= body.search('xref[ref-type=bibr]')
    end

  end
end
