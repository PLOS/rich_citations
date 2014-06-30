require 'json'
require 'uri'
require 'net/http'

class HttpUtilities

  def self.get(url, headers={})
    redirect_count = 0
    redirects = []
    http = Net::HTTP::Persistent.new
    # http.debug_output = $stdout

    loop do
      # puts "GET #{url}"
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

  def self.post(url, content, headers={})
    redirect_count = 0
    redirects = []
    http = Net::HTTP::Persistent.new
    # http.debug_output = $stdout
    http.retry_change_requests = true

    loop do
      # puts "POST #{url}"
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
        { 'Accept' => Mime::XML.to_s }
      when :json
        { 'Accept' => Mime::JSON.to_s }
      when :js
        { 'Accept' => Mime::JS.to_s }
      when Symbol
        { 'Accept' => "application/#{original}" }
      when String
        { 'Accept' => original }
      when Hash
        original.each { |k,v| original[k] = v.to_s }
      else
        original
    end
  end

end
