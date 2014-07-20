# Some general helpers
module Processors::Helpers

  protected

  def body
    @body ||= xml.search('body').first || xml
  end

  def state
    result[:state] ||= ActiveSupport::OrderedOptions.new
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

  def reference_by_identifier(type, identifier)
    type = type.to_sym
    references.find { |id, ref|
      ref[:id_type]==type && ref[:id]==identifier }.try(:second
    )
  end

  def references_for_type(type)
    type = type.to_sym
    references.values.select { |ref| ref[:id_type] == type }
  end

  def references_without_info(type)
    references_for_type(type).reject { |ref| ref[:info] && ref[:info][:info_source] }
  end

  def citation_groups
    @citation_groups ||= result[:groups]
  end

end