
module Id
  class Base

    PUNCT  = %q{[\]'"`.,:;!)\-\/]}  # Posix [[:punct:]] regex is more liberal than we want
    NPUNCT = %q{[^\]'"`.,>[[:space:]]:;!)\-\/]}

    private

    # Regexes must have a named capture called 'result'
    def self.match_regexes(text, regexes)
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