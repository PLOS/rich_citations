module Processors
  class CitationGroups < Base
    include Helpers

    # A citation group is all of the papers that are cited together at a certain point in the paper
    # -- the bare stuff of inline co-citations.
    # So, for example, a citation group might simply be [1], or it could be [2]-[10], or even
    # [11], [13]-[17], [21].

    def process
      result[:groups] = citation_groups
    end

    def cleanup
      result[:groups].each do |group|
        group.delete(:nodes)
        group.compact!
      end
    end

    def self.dependencies
      [References]
    end

    ####################################################do
    # Callbacks for CitationGrouper

    #@mro rewrite to
    # Find the reference number for an XREF node
    def reference_number(xref_node)
      index, ref = reference_for_citation_node(xref_node)
      index
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