
module Plos
  class Utilities

    def self.extract_doi(text)
      match = text.match( /\sdoi:|\.doi\./i)
      return nil unless match

      # all DOI's start with 10., see reference here: http://www.doi.org/doi_handbook/2_Numbering.html#2.2
      match = text.match( /(\s)*(10\.)/, match.end(0) )
      return nil unless match

      match = text.match( /[^\s\"]*/, match.begin(2))
      result = match[0]
      result = result[0..-2] if result.end_with?('.')
      result
    end

  end
end