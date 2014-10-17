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

class JsonUtilities
  # Hack to remove :uri_type. Modifies data structure in place.
  def self.strip_uri_type!(input)
    input.delete(:uri_type)
    input[:references] && input[:references].each do |ref|
      ref.delete(:uri_type)
    end
    input
  end

  def self.encode_uri(uri)
    return nil if uri.nil?
    # properly encode DOI URIs
    md = uri.match(%r{^http://dx.doi.org/(.*)$})
    if md
      doi_enc = URI.encode_www_form_component(md[1])
      "http://dx.doi.org/#{doi_enc}"
    else
      URI.encode(uri)
    end
  end

  # hack to fix dx.doi.org encoding.
  def self.clean_uris!(json)
    if json.is_a? Hash
      json.keys.each do |k|
        if (k == 'uri')
          json[k] = JsonUtilities.encode_uri(json[k])
        else
          JsonUtilities.clean_uris!(json[k])
        end
      end
    elsif json.is_a? Array
      json.each do |v|
        JsonUtilities.clean_uris!(v)
      end
    end
  end
end
