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
  class Arxiv < Base
    # cf http://arxiv.org/help/arxiv_identifier

    # yymm.nnnn(Vn)
    NEW_ARXIV_REGEX = '\d{4}\.?\d{4,5}(v\d{1,3})?'
    # subject/yymmnnn - subject can be alpha & . or -
    OLD_ARXIV_REGEX = '[a-z0-9.-]+\/\d{7}(v\d{1,3})?'

    NEW_URL_REGEX    = /arxiv\.org\/abs\/(?<result>#{NEW_ARXIV_REGEX})\b/io
    OLD_URL_REGEX    = /arxiv\.org\/abs\/(?<result>#{OLD_ARXIV_REGEX})\b/io
    NEW_PREFIX_REGEX = /\barxiv(\s*id)?:?\s*(?<result>#{NEW_ARXIV_REGEX})\b/io
    OLD_PREFIX_REGEX = /\barxiv(\s*id)?:?\s*(?<result>#{OLD_ARXIV_REGEX})\b/io

    NEW_ID_REGEX    = /\A#{NEW_ARXIV_REGEX}\z/io
    OLD_ID_REGEX    = /\A#{OLD_ARXIV_REGEX}\z/io

    def self.extract(text)
      normalize( match_regexes(text, NEW_URL_REGEX     => true,
                                     OLD_URL_REGEX     => true,
                                     NEW_PREFIX_REGEX  => false,
                                     OLD_PREFIX_REGEX  => false
      ) )
    end

    def self.id(text)
      if text && (text =~ NEW_ID_REGEX || text =~ OLD_ID_REGEX)
        normalize(text)
      else
        nil
      end
    end
    def self.is_id?(text); id(text); end

    # Assumes the input is a valid Arxiv ID
    def self.without_version(id)
      id = normalize(id)
      id && id.sub(/v\d+$/i, '')
    end

    def self.normalize(id)
      id = id.try(:strip)
      if id.blank?
        nil
      elsif id =~ /\d{8}/ # New version without period
        id.insert(4,'.')
      else
        id
      end
    end

  end
end
