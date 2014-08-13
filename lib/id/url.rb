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

module Id
  class Url < Base
    # Url with or without retrieved date
    # Note this works slightly differently to other parses because I need the context to find the retrieved date

    CHAR            = %q{[^"'\s]}
    TRAILING_CHAR   = NPUNCT
    PROTOCOL        = '(https?)'
    URL             = "#{PROTOCOL}\:\/\/ #{CHAR}*#{TRAILING_CHAR}"

    URL_REGEX       = /(?<result>#{URL})/iox

    ACCESSED_PREFIX = /^(Retrieved|Accessed) \s* #{PUNCT}* \s* /iox

    def self.extract(text)
      normalize( match_regexes(text, URL_REGEX => false) )
    end

    def self.extract_from_xml(xml)
      # Try and extract it either from an href attribute
      xml.css('*').each do |node|
        href = node['href'] || node['xlink:href']
        url  = extract(href)
        return {
            url:      url,
            accessed: extract_date( XmlUtilities.text_after(xml, node) )
        }.compact if url.present?
      end

      text = xml.text
      url = extract(text)
      return nil unless url.present?

      offset = text.index(url) + url.length
      {
        url:      url,
        accessed: extract_date( text[offset..-1] )
      }.compact if url.present?
    end

    private

    def self.extract_date(text)
      # Remove starting whitespace and punctuation
      text.sub!(/^(#{PUNCT}|\s)*/iox, '')

      # Remove a string that looks like 'Retrieved' or 'Accessed'
      text.sub!(ACCESSED_PREFIX, '')

      begin
        Date.parse(text)
      rescue ArgumentError
        nil
      end
    end

  end
end
