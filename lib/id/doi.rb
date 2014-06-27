module Id
  class Doi < Base

    # (^|\s)doi:?\s*(?<result>10\.([[:punct:]]*[^[[:punct:]][[:space:]]]+)+)
    DOI_REGEX = '10\.\S+\/\S+'
    DOI_PREFIX_REGEX = /(^|\s)doi:?\s*(?<result>#{DOI_REGEX}(?<!#{PUNCT}))/io
    DOI_URL_REGEX    = /(^|\W)doi\.org\/(?<result>#{DOI_REGEX}(?<!#{PUNCT}))/io
    DOI_ALONE_REGEX  = /^(#{PUNCT}|\s)*(?<result>#{DOI_REGEX}(?<!#{PUNCT}))/io

    PLOS_PREFIXES = [ '10.1371' ]

    def self.extract(text)
      match_regexes(text, DOI_URL_REGEX    => true,
                          DOI_PREFIX_REGEX => false,
                          DOI_ALONE_REGEX  => false  )
    end

    def self.extract_list(text)
      list = (text || '').split(/(",|',|`,|\s)\s*/)
      list.map!{|i| extract(i) }
      list.select(&:present?)
    end

    def self.prefix(doi)
      doi && doi.strip.split('/',2).first
    end

    def self.is_plos_doi?(doi)
      prefix(doi).in?(PLOS_PREFIXES)
    end

  end
end