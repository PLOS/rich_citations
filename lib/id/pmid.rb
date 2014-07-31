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
  class Pmid < Base
    # PMID or PubmedID

    # 10 or 13 digits with optional hypehns
    PUBMED_REGEX = '(\d{4,20})'
    PUBMED_PREFIX_REGEX = /\b(pmid|pubmed|pubmed\s*id):?\s*(?<result>#{PUBMED_REGEX})(#{PUNCT}|\s|$)/io

    def self.extract(text)
      normalize( match_regexes(text, PUBMED_PREFIX_REGEX => false ) )
    end

    def self.normalize(pmid)
      pmid.present? ? pmid.gsub(/[^0-9]/,'') : nil
    end

  end
end
