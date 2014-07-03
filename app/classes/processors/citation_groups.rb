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

    def index_for_citation_node(xref_node)
      refid = xref_node['rid']
      ref   = reference_by_id(refid)
      ref && ref[:index]
    end

    def reference_id_for_index(index)
      ref = reference_by_index(index)
      ref && ref[:ref_id]
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