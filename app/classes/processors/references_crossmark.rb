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

module Processors
  class ReferencesCrossmark < Base
    include Helpers

    def process
      references_for_type(:doi).each do |ref|
        next if ref[:updated_by]

        doi = ref[:uri]
        get_crossmark_info(doi, ref) if doi
      end
    end

    def self.dependencies
      ReferencesIdentifier
    end

    protected

    def get_crossmark_info(doi, ref)
      doi_enc = URI.encode_www_form_component(doi)
      result = Rails.cache.fetch("crossmark_#{doi_enc}", :expires_in=> 108000) do
        url = "http://crossmark.crossref.org/crossmark/?doi=#{doi_enc}"
        begin
          JSON.parse(HttpUtilities.get(url), symbolize_names:true)
        rescue Net::HTTPFatalError #@mro #@todo
          {}
        rescue Net::HTTPServerException => ex
          raise unless ex.response.is_a?(Net::HTTPNotFound)
          {}
        end
      end

      ref[:updated_by] = result[:updated_by]
    end
  end
end
