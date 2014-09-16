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
  class ReferencesLicense < Base
    include Helpers

    SLICE_SIZE = 20
    
    #@todo #@pubmed - this API can handle pubmed ids

    def process
      references = references_without_licenses
      return if references.blank?

      references.each_slice(SLICE_SIZE) do |group|
        begin
          add_licenses(get_licenses(group))
        rescue Net::HTTPFatalError
          # try each item one at a time
          group.each do |item|
            begin
              add_licenses(get_licenses([item]))
            rescue Net::HTTPFatalError
            end
          end
        end
      end

      state.license_retrieved_time = timestamp if !is_delayed?
    end

    # Execute as soon as possible to maximize the time between this and DelayedReferencesLicense
    def self.priority
      1
    end

    def self.dependencies
      [State, ReferencesInfoCacheLoader]
    end

    protected

    API_URL = 'http://howopenisit.org/lookup'

    def is_delayed?
      false
    end

    def timestamp
      Time.now
    end

    def references_without_licenses
      references_for_type(:doi).select { |ref| ! ref[:bibliographic][:license] }
    end

    def get_licenses(references)
      data = references.map { |ref| {type:'doi', id:ref[:uri]} }
      results = HttpUtilities.post(API_URL, JSON.generate(data),
                          'Accept' => Mime::JSON, 'Content-Type' => Mime::JSON
      )
      JSON.parse(results)
    end

    def add_licenses(results)
      Array(results['results']).each do |result|
        ref     = get_reference(result['identifier'] )
        license = get_license( result['license'] )
        next unless ref && license

        ref[:bibliographic][:license] = license['type']
      end
    end

    def get_reference(identifiers)
      identifiers.each do |identifier|
        ref = reference_by_uri(identifier['type'], identifier['id'])
        return ref if ref
      end
      return nil
    end

    def get_license( licenses )
      prioritized_licenses = licenses.sort_by { |license|
        date = Time.parse( license['provenance']['date'] )
        # Prioritize active licenses
        license['status']=='active' ? date : date - 1000.years
      }
      prioritized_licenses.last
    end

  end
end
