module Id
  class Pmid < Base
    # PMID or PubmedID

    # 10 or 13 digits with optional hypehns
    PUBMED_REGEX = '(\d{4,20})'
    PUBMED_PREFIX_REGEX = /(^|\s)(pmid|pubmed|pubmed\s*id):?\s*(?<result>#{PUBMED_REGEX})(#{PUNCT}|\s|$)/io

    def self.extract(text)
      normalize( match_regexes(text, PUBMED_PREFIX_REGEX => false ) )
    end

    def self.normalize(isbn)
      isbn.present? ? isbn.gsub(/[^0-9]/,'') : nil
    end

  end
end