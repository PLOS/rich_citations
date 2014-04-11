
module Plos
  class Utilities
    PUNCT = %q{[\]'"`.,:;!)\-\/]} # Posix [[:punct:]] regex is more liberal than we want

    # (^|\s)doi:?\s*(?<result>10\.([[:punct:]]*[^[[:punct:]][[:space:]]]+)+)

    DOI_PREFIX_REGEX = /(^|\s)doi:?\s*(?<result>10\.\S+(?<!#{PUNCT}))/io
    DOI_URL_REGEX    = /(^|\W)doi\.org\/(?<result>10\.\S+(?<!#{PUNCT}))/io

    def self.extract_doi(text)
      match(text, { DOI_URL_REGEX    => true,
                    DOI_PREFIX_REGEX => false })
    end

    # Regexes must have a named capture called 'result'
    def self.match(text, regexes)
      return nil unless text.present?

      regexes.each do |regex, unescape|
        match = text.match(regex)
        next unless match

        result = match['result']
        result = CGI.unescape(result) if unescape
        return result
      end

      nil
    end

  end
end