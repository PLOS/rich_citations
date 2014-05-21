module Plos
  module Doi
    extend self # Make everything a module method

    # (^|\s)doi:?\s*(?<result>10\.([[:punct:]]*[^[[:punct:]][[:space:]]]+)+)
    DOI_REGEX = '10\.\S+\/\S+'
    DOI_PREFIX_REGEX = /(^|\s)doi:?\s*(?<result>#{DOI_REGEX}(?<!#{Plos::Utilities::PUNCT}))/io
    DOI_URL_REGEX    = /(^|\W)doi\.org\/(?<result>#{DOI_REGEX}(?<!#{Plos::Utilities::PUNCT}))/io
    DOI_ALONE_REGEX  = /^(#{Plos::Utilities::PUNCT}|\s)*(?<result>#{DOI_REGEX}(?<!#{Plos::Utilities::PUNCT}))/io

    PLOS_PREFIXES = [ '10.1371' ]

    def extract(text)
      Plos::Utilities.match_regexes(text, { DOI_URL_REGEX    => true,
                                            DOI_PREFIX_REGEX => false,
                                            DOI_ALONE_REGEX  => false  })
    end

    def extract_list(text)
      list = (text || '').split(/(",|',|`,|\s)\s*/)
      list.map!{|i| extract(i) }
      list.select(&:present?)
    end

    def prefix(doi)
      doi && doi.strip.split('/',2).first
    end

    def is_plos_doi?(doi)
      prefix(doi).in?(PLOS_PREFIXES)
    end

  end
end