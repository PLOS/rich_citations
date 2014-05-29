# Some general helpers
module Processors::Helpers

  protected

  def body
    @body ||= xml.search('body').first || xml
  end

  def references
    @references ||= result[:references]
  end

  def reference_by_id(id)
    references[id]
  end

  def reference_by_index(index)
    references.find { |id, ref| ref[:index] == index }.try(:second)
  end

  def reference_by_identifier(identifier)
    references.find { |id, ref| ref[:doi] == identifier }.try(:second)
  end

  def citation_groups
    @citation_groups ||= result[:groups]
  end

end