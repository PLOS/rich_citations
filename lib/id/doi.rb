module Id
  class Doi < Base

    # DOI parsing is painful since, in theory, a DOI can contain any character
    # The following assumptions are made:
    #   A DOI cannot contain (unencoded) whitespace or quotes (Since they might be in an attribute)
    #   A DOI cannot end with punctuation (so that we can separate a DOI from following punctuation)

    DOI_PREFIX_CHAR  = %q{[^\/[[:space:]]]}
    DOI_CHAR         = %q{[^[[:space:]]'"]}
    DOI_END_CHAR     = NPUNCT
    DOI_REGEX        = "10\\.#{DOI_PREFIX_CHAR}+\\/#{DOI_CHAR}*#{DOI_END_CHAR}+"

    DOI_PREFIX_REGEX = /(^|\s)doi:?\s*(?<result>#{DOI_REGEX})/io
    DOI_URL_REGEX    = /(^|\W)doi\.org\/(?<result>#{DOI_REGEX})/io
    DOI_ALONE_REGEX  = /^(#{PUNCT}|\s)*(?<result>#{DOI_REGEX})/io

    PLOS_PREFIXES = [ '10.1371' ]

    def self.extract(text, normalize=false)
      doi = match_regexes(text, DOI_URL_REGEX    => true,
                                DOI_PREFIX_REGEX => false,
                                DOI_ALONE_REGEX  => false  )

      doi = cleanup(doi)
      normalize ? normalize(doi) : doi
    end

    def self.extract_list(text)
      list = (text || '').split(/(",|',|`,|\s)\s*/)
      list.map!{|i| extract(i) }
      list.select(&:present?)
    end

    def self.normalize(doi)
      doi.present? ? doi.strip.tr('–','-') : nil
    end

    def self.prefix(doi)
      doi && doi.strip.split('/',2).first
    end

    def self.is_plos_doi?(doi)
      prefix(doi).in?(PLOS_PREFIXES)
    end

    private

    # Some stuff which is just too tricky to handle with regexes
    def self.cleanup(doi)
      # Handle DOIs that have an ending XML delimiter in them
      if doi =~ /<\//
        doi = doi.sub(/<\/.*/,'')
        doi = doi.sub(/#{PUNCT}+$/o,'')
      end

      doi
    end

  end
end