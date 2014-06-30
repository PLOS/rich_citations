module Id
  class Isbn < Base

    # 10 or 13 digits with optional hypehns
    ISBN_REGEX = '(\d{3}\-?)?(\d\-?){9}(\d|X)'
    ISBN_PREFIX_REGEX = /(^|\s)isbn:?\s*(?<result>#{ISBN_REGEX})(#{PUNCT}|\s|$)/io
    # ISBN_PREFIX_REGEX = /(^|\s)isbn:?\s*(?<result>#{ISBN_REGEX})/io

    def self.extract(text)
      normalize( match_regexes(text, ISBN_PREFIX_REGEX => false ) )
    end

    def self.normalize(isbn)
      isbn.present? ? isbn.strip.tr('-','').upcase : nil
    end

  end
end