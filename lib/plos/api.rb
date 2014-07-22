require 'json'
require 'uri'
require 'net/http'

module Plos
  class Api

    SEARCH_URL   = 'http://api.plos.org/search'
    DOC_URL      = 'http://www.plosone.org/article/fetchObjectAttachment.action?uri=info:doi/%s&representation=XML'
    INFO_URL     = 'http://www.plosone.org/article/info:doi/%s'

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
      url = DOC_URL % [doi]
      response = Rails.cache.fetch("#{doi}_xml", :expires_in=> 108000) do
        HttpUtilities.get(url, :xml)
      end
      Nokogiri::XML(response)

    rescue Net::HTTPFatalError => ex
      raise unless ex.response.code == '500'
      #todo Need a better way to detect invalid docs than 500 errors
      nil
    end

    # Given the DOI of a PLOS paper, downloads the XML and parses it
    def self.info(doi)
      url = INFO_URL % [doi]
      response = HttpUtilities.get(url)
      Nokogiri::HTML(response)
    end

  end
end
