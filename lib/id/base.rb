# Copyright (c) 2014 Public Library of Science

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
  class Base

    PUNCT  = %q{[\]'"`.,:;!)\-\/]}  # Posix [[:punct:]] regex is more liberal than we want
    NPUNCT = %q{[^\]'"`.,>[[:space:]]:;!)\-\/]}

    def self.normalize(id)
      id ? id.strip.presence : nil
    end

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
