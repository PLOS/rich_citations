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

class HttpUtilities

  def self.get(url, headers={})
    redirect_count = 0
    redirects = []
    http = Net::HTTP::Persistent.new
    # http.debug_output = $stdout

    loop do
      puts "GET #{url}"
      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri.request_uri, parse_headers(headers))
      response = http.request uri, req

      location = response.header['location']
      if location
        raise "Recursive redirect" if redirects.include?(location)
        raise "Too many redirects" if redirect_count >= 5
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
    retry_count = 0
    redirects = []
    http = Net::HTTP::Persistent.new
    # http.debug_output = $stdout

    loop do
      # puts "POST #{url}"
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.request_uri, parse_headers(headers))
      req.body = content
      response = http.request uri, req

      location = response.header['location']
      if location
        raise "Recursive redirect" if redirects.include?(location)
        raise "Too many redirects" if redirect_count >= 3
        redirect_count += 1
        redirects << location
        url = location
      elsif (response.code.to_i == 502)
        response.value if retry_count > 2
        retry_count +=1
        # slow it down
        http.shutdown
        sleep 5*retry_count
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
