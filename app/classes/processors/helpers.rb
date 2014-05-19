# Some general helpers
module Processors::Helpers

  protected

  def body
    @body ||= xml.search('body').first || xml
  end

  def references
    @references ||= result[:references]
  end

  def reference_by_number(num)
    references[num]
  end

  def reference_by_id(refid)
    references.find { |index, ref| ref[:id] == refid }.second
  end

  def reference_for_citation_node(node)
    # Find the reference number for an XREF node
    refid = node['rid']
    references.find { |index, ref| ref[:id] == refid } || warn("There was an error getting the reference for #{refid}") || 0
  end

  def citation_groups
    @citation_groups ||= result[:groups]
  end

end