require 'uri'

module Processors
  class ReferencesInfoFromCitationText < Base
    include Helpers

    def process
      references.each do |id, ref|
        extract_citation_info(ref[:node], ref[:info])
      end
    end

    def self.dependencies
      ReferencesInfoFromCitationNode
    end

    protected

    def extract_citation_info(node, info)
      cite = node.at_css('mixed-citation')
      return unless cite.present?

      matches = cite.text.match(/(?<authors>.+)\((?<year>\d{4})\)(?<title>.+)/)
      return unless matches

      @field_changed = false

      set_field info, :title, matches[:title]

      # Ad year issued
      if matches[:year].present?
        year = matches[:year].to_i
        set_field info, :issued, :'date-parts' => [[year]]
      end

      # Add page range
      if matches[:authors].present?
        set_field info, :author, [ literal:matches[:authors].strip ]
      end

      set_field(info, :info_source, 'RefText') if @field_changed
    end

    def set_field(info, field, value)
      if info[field].blank?
        value = value.strip if value.respond_to?(:strip)

        if value.present? && value != info[field]
          @field_changed = true
          info[field] = value
        end
      end
    end

  end
end
