# Copyright (c) 2014 Nathan Day

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
  class Wikipedia < Url
    # Url with or without retrieved date
    # Note this works slightly differently to other parses because I need the context to find the retrieved date

    LANGUAGE         = "[[:alpha:]]{2,3}"
    DOMAIN           = "wikipedia.org"
    PATH             = "wiki"
    PAGE             = "#{CHAR}+"
    URL_REGEX        = %r!(?<result>#{PROTOCOL}\:\/\/(?:#{LANGUAGE}\.)?#{DOMAIN}/#{PATH}/#{PAGE})!iox
    URL_PARTS_REGEX  = %r!(#{PROTOCOL}\:\/\/(?:(?<language>#{LANGUAGE})\.)?#{DOMAIN}/#{PATH}/(?<page>#{PAGE}))!iox

    def self.extract(text, strict=false)
      normalize( match_regexes(text, URL_REGEX => false) )
    end

    def self.extract_from_xml(xml)

      # Try and extract it either from an href attribute
      xml.xpath('//*').each do |node|

        href = node['href'] || node['xlink:href']
        url  = extract(href, true)

        if url
          return match_url_parts(url).merge!(
              get_accessed_date(XmlUtilities.text_after(xml, node))
          ).compact
        end
      end

      # attempt to extract url from text node of the reference
      text = xml.text
      url = extract(text, false)
      return nil unless url.present?
      offset = text.index(url) + url.length
      return match_url_parts(url).merge!(
          get_accessed_date(text[offset..-1])
      ).compact
    end

    def self.match_url_parts(url)
      matches = url.match(URL_PARTS_REGEX)
      language = matches[:language]
      page = matches[:page]
      { url:      url,
        language: language,
        page:     page
      }.compact
    end

    def self.get_accessed_date(text)
      return { accessed_at: extract_date(text) } if text && text.length > 0
      return {}
    end

  end
end
