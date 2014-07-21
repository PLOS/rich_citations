require 'uri'

module Processors
  class ReferencesInfoFromCitationNode < Base
    include Helpers

    def process
      references.each do |id, ref|
        extract_citation_info(ref[:node], ref[:info])
      end
    end

    def self.dependencies
      [ReferencesInfoFromDoi, ReferencesInfoFromIsbn, ReferencesInfoFromPubmed, ReferencesInfoFromPmc]
    end

    protected

    def extract_citation_info(node, info)
      cite = node.at_css('mixed-citation')
      return unless cite.present?

      @field_changed = false

      set_field info, :'container-type',  cite['publication-type']
      set_field info, :'container-title', cite.at_css('source')
      set_field info, :title,             cite.at_css('article-title').try(:inner_html)
      set_field info, :volume,            cite.at_css('volume')

      # Ad year issued
      if cite.at_css('year').present?
        year = cite.at_css('year').text.to_i
        set_field info, :issued, :'date-parts' => [[year]]
      end

      # Add page range
      if cite.at_css('fpage').present?
        from = cite.at_css('fpage').text
        to   = cite.at_css('lpage').present? ? cite.at_css('lpage').text : from
        set_field info, :page, "#{from}-#{to}"
      end

      extract_citation_names(node, info)

      set_field(info, :info_source, 'RefNode') if @field_changed
    end

    def extract_citation_names(node, info)
      return if info[:author].present?
      names = node.css('name')
      return unless names.present?

      authors = names.map do |name|
        {
            family: name.css('surname'    ).text.strip.presence,
            given:  name.css('given-names').text.strip.presence,
        }.compact
      end

      set_field info, :author, authors
    end

    def set_field(info, field, value)
      if info[field].blank?
        value = value.content if value.respond_to?(:content)
        value = value.strip if value.respond_to?(:strip)

        if value.present? && value != info[field]
          @field_changed = true
          info[field] = value
        end
      end
    end

  end
end
