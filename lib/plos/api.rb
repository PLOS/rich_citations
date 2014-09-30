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

require 'json'
require 'uri'
require 'net/http'

module Plos
  class Api

    SEARCH_URL   = 'http://api.plos.org/search'
    DOC_URL      = 'http://www.plosone.org/article/fetchObjectAttachment.action?uri=info:doi/%s&representation=XML'

    #Accesses the PLOS search API.
    #query: the text of your query.
    #query_type: subject, author, etc.
    #rows: maximum number of results to return.
    #more_parameters: an optional dictionary; key-value pairs are parameter names and values for the search api.
    #fq: determines what kind of results are returned.
    #Set by default to return only full documents that are research articles (almost always what you want).
    #output: determines output type. Set to JSON by default, XML is also possible, along with a few others.
    #Note that the PLOS search API cannot return full paper text, only abstracts and metadata.
    #However, the URL for retrieving full-text PLOS papers is wholly specified by a paper's DOI (journal is not necessary).

    def self.search(query, query_type:nil, rows:20, more_parameters:nil, fq:'doc_type:full AND article_type_facet:"Research Article"', output: :json)
      params = {}

      query = URI.encode_www_form_component("\"#{query}\"")
      query = "#{query_type}:#{query}" if query_type
      params[:q] = query

      if more_parameters
        more_parameters.each do |k,v|
          params[k] = URI.encode_www_form_component(v)
        end
      end

      params[:fq]      = URI.encode_www_form_component(fq) if fq
      params[:wt]      = output
      params[:rows]    = rows
      params[:api_key] = Rails.configuration.app.plos_api_key

      query_string = params.map{ |k,v| "#{k}=#{v}"}.join('&')
      url = SEARCH_URL + '?'+query_string
      response = HttpUtilities.get(url, output)
      json = JSON.parse(response)
      json['response']['docs']
    end

    def self.search_dois(dois)
      dois = dois.map { |doi| %("#{URI.encode_www_form_component(doi)}") }
      query = "q=id:(#{dois.join('+OR+')})"
      url = SEARCH_URL + "?rows=#{dois.count}&wt=json&api_key=#{Rails.configuration.app.plos_api_key}"

      response = HttpUtilities.post(url,
                                    query,
                                   'Accept'       => Mime::JSON,
                                   'Content-Type' => Mime::URL_ENCODED_FORM )

      json = JSON.parse(response)
      json['response']['docs']
    end

    # Given the DOI of a PLOS paper, downloads the XML and parses it
    def self.document(doi)
      # HACK - but since we will be rewriting this, not a big deal now
      if Id::Doi.is_elife_doi?(doi)
        return Elife::Api.document(doi)
      elsif Id::Doi.is_peerj_doi?(doi)
        return Peerj::Api.document(doi)
      else
        begin
          url = DOC_URL % [doi]
          response = Rails.cache.fetch("#{doi}_xml", :expires_in=> 108000) do
            HttpUtilities.get(url, :xml)
          end
          Loofah.xml_document(response)
          
        rescue Net::HTTPFatalError => ex
          raise unless ex.response.code == '500'
          #todo Need a better way to detect invalid docs than 500 errors
          nil
        end
      end
    end
  end
end
