# Copyright (c) 2014 Nathan Day

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

require 'uri'

module Processors
  class ReferencesInfoFromCoins < Base
    include Helpers

    # slightly lower priority than the URL handler, since this class's recognizer is also a URL
    def self.priority
      49
    end

    protected

    # doc:          Nokogiri XML document object
    # key_mapping:  COINs => Rich Citations name mapping
    # constraints:  key => val requirements in COINs data (e.g., format)
    def self.extract_coins(doc,key_mapping,constraints)
      title = doc.xpath('string(//span[contains(@class,"Z3988")][1]/@title)')
      return unless title
      params = CGI::parse(title)
      return unless params.length > 0
      # flatten values, which were parsed as { a => ["b"] }
      params.each{|key,value| params[key] = value.first}
      # check constraints
      constraints.each{|ck,cv|
        raise("Unmet constraint for COINs mapping for key: %s" % ck) unless (params.has_key?(ck) && params[ck].eql?(cv))
      }
      # return mapped values
      Hash[key_mapping.map{|coins,theirs| [theirs, params[coins]] }].compact
    end

  end

end

