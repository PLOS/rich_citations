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

require 'uri'

module Processors
  class ReferencesInfoFromDoi < Base
    include Helpers

    def process
      references_without_info(:doi).each do |ref|
        doi = ref[:id]
        get_doi_info(doi, ref) if doi
      end
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf http://www.crosscite.org/cn/
    # This API always does a redirect. If we can guess the source ebfore hand we could optimize slightly
    # see Pivotal #72716068

    API_URL = "http://dx.doi.org/"

    def get_doi_info(doi, ref)
      result = get_result(doi)
      result = result.except(:id, :id_type, :id_source, :info_source, :score)
      ref[:info].merge!(result).merge!(info_source:'dx.doi.org')
    end

    def get_result(doi)
      url  = API_URL + URI.encode_www_form_component(doi)
      json = HttpUtilities.get(url, 'application/citeproc+json')
      JSON.parse(json, symbolize_names:true)
    rescue Net::HTTPServerException => ex
      raise unless ex.response.is_a?(Net::HTTPNotFound)
      {}
    end

  end
end
