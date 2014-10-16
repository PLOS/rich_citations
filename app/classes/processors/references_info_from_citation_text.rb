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

require 'uri'

module Processors
  class ReferencesInfoFromCitationText < Base
    include Helpers

    def process
      references.each do |ref|
        extract_citation_info(ref[:node], ref[:bibliographic])
      end
    end

    def self.dependencies
      ReferencesInfoFromCitationNode
    end

    protected

    def extract_citation_info(node, info)
      cite = node.at_css('mixed-citation')
      return unless cite.present?

      matches = cite.inner_html.match(/(?<authors>.+)\((?<year>\d{4})\)(?<title>.+)/)
      return unless matches

      @field_changed = false

      set_field info, :title, XmlUtilities.jats2html(matches[:title])

      # Ad year issued
      if matches[:year].present?
        year = matches[:year].to_i
        set_field info, :issued, :'date-parts' => [[year]]
      end

      # Add page range
      if matches[:authors].present?
        set_field info, :author, [ literal:matches[:authors].strip ]
      end

      set_field(info, :bib_source, 'RefText') if @field_changed
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
