require 'json'
require 'uri'
require 'net/http'

module Plos
  class Api

    SEARCH_URL   = 'http://api.plos.org/search'
    DOC_URL      = 'http://www.plosone.org/article/fetchObjectAttachment.action?uri=info:doi/%s&representation=XML'
    INFO_URL     = 'http://www.plosone.org/article/info:doi/%s'

    # This is Adam's API key. Please don't overuse it.
    # We're going to need a different one (or a different arrangement altogether) for any public release.
    API_KEY = "s4ZVBmgJyfZPMpqyy3Gs" # for abecker@plos.org

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

      query = URI.encode("\"#{query}\"")
      query = "#{query_type}:#{query}" if query_type
      params[:q] = query

      if more_parameters
        more_parameters.each do |k,v|
          params[k] = URI.encode(v)
        end
      end

      params[:fq]      = URI.encode(fq) if fq
      params[:wt]      = output
      params[:rows]    = rows
      params[:api_key] = API_KEY

      query_string = params.map{ |k,v| "#{k}=#{v}"}.join('&')
      url = SEARCH_URL + '?'+query_string
      response = http_get(url, output)
      json = JSON.parse(response)
      json['response']['docs']
    end

    # Given the DOI of a PLOS paper, downloads the XML and parses it
    def self.document(doi)
      url = DOC_URL % [doi]
      response = http_get(url, :xml)
      Nokogiri::XML(response)
    end

    # Given the DOI of a PLOS paper, downloads the XML and parses it
    def self.info(doi)
      url = INFO_URL % [doi]
      response = http_get(url)
      Nokogiri::HTML(response)
    end

    def self.http_get(url, headers={})
      redirect_count = 0
      redirects = []
      http = Net::HTTP::Persistent.new
      # http.debug_output = $stdout

      loop do
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri.request_uri, parse_headers(headers))
        response = http.request uri, req

        location = response.header['location']
        if location
          raise "Recursive redirect" if redirects.include?(location)
          raise "Toom many redirects" if redirect_count >= 3
          redirect_count += 1
          redirects << location
          url = location

        else
          response.value
          return response.body
        end

      end
    end

    def self.http_post(url, content, headers={})
      redirect_count = 0
      redirects = []
      http = Net::HTTP::Persistent.new

      loop do
        uri = URI.parse(url)
        req = Net::HTTP::Post.new(uri.request_uri, parse_headers(headers))
        req.body = content
        response = http.request uri, req

        location = response.header['location']
        if location
          raise "Recursive redirect" if redirects.include?(location)
          raise "Toom many redirects" if redirect_count >= 3
          redirect_count += 1
          redirects << location
          url = location

        else
          response.value
          return response.body
        end

      end
    end

    private

    def self.parse_headers(original)
      case original
        when :xml
          { 'Content-Type' => 'application/xml' }
        when :json
          { 'Content-Type' => 'application/json' }
        when :js
          { 'Content-Type' => 'application/javascript' }
        ekse
          original
      end
    end
  end
end