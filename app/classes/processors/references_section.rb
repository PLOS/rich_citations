# Add sections node

module Processors
  class ReferencesSection < Base
    include Helpers

    def process
      references.each do |id, info|
        add_sections_for_reference(id, info)
      end
    end

    def self.dependencies
      [References, CitationGroupSection]
    end

    protected

    def add_sections_for_reference(id, ref)
      citation_groups.each do |group|
        add_section(ref, group) if id.in?(group[:references])
      end
    end

    def add_section(ref, group)
      sections        = ref[:sections] ||= {}
      title           = group[:section]
      sections[title] = sections[title].to_i + 1
    end

  end
end