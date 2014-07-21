module Id
  class Pmcid < Base
    # PMID or PubmedID

    # 10 or 13 digits with optional hypehns
    PMCID_REGEX = '(\d{4,20})'
    # Prefixed with pmcid and punctuation
    PMCID_PREFIX_REGEX    = /\b(pmcid|pubmed\s*commons\s*id):?\s*(?<result>(PMC)?#{PMCID_REGEX})(#{PUNCT}|\s|$)/io
    # Number directly prefixed by PMC
    PMCID_NO_PREFIX_REGEX = /\b(?<result>PMC#{PMCID_REGEX})(#{PUNCT}|\s|$)/io

    def self.extract(text)
      normalize( match_regexes(text, PMCID_PREFIX_REGEX => false,
                                     PMCID_NO_PREFIX_REGEX => false) )
    end

    def self.normalize(pmcid)
      return nil unless pmcid.present?
      'PMC' + pmcid.gsub(/[^0-9]/,'')
    end

  end
end