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
  class ReferencesInfoFromIsbn < Base
    include Helpers

    def process
      # Process in groups since IDs have to fit in a URL
      references_without_bib_info(:isbn).each_slice(10) do |references|
        fill_info_for_references(references)
      end
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf https://openlibrary.org/dev/docs/api/books
    #    We might also want to look at https://openlibrary.org/dev/docs/api/read
    #    This API currently supports ISBNs, LCCNs, OCLC numbers and OLIDs
    #    Since ids are in the url we cannot do more than a few at a time

    API_URL = 'http://openlibrary.org/api/volumes/brief/json/'

    def fill_info_for_references(references)
      references = references.map { |ref| [ "ISBN:#{ref[:uri]}", ref]}.to_h

      results = fetch_results_for_ids(references.keys)

      results.each do |id, result|
        info = convert_result_to_info(result)
        references[id][:bibliographic] ||= {}
        references[id][:bibliographic].merge!(info)
      end
    end

    def fetch_results_for_ids(ids)
      url    = API_URL + ids.join( URI.encode_www_form_component('|') )
      json   = HttpUtilities.get(url, :json)
      JSON.parse(json, symbolize_names:false)
    end

    def convert_result_to_info(result)
      result.symbolize_keys_recursive!
      data    = (result[:records] && result[:records].values.first[:data])    || {}
      details = (result[:records] && result[:records].values.first[:details].try(:[], :details) ) || {}

      {
          info_source:       'OpenLibrary',
          key:               data[:key],
          ISBN:              data[:identifiers] && (data[:identifiers][:isbn_13] || data[:identifiers][:isbn_10]),
          OLID:              data[:identifiers] && data[:identifiers][:openlibrary],
          OCLC:              data[:identifiers] && data[:identifiers][:oclc],
          title:             data[:title],
          subtitle:          [data[:subtitle]].compact.presence,
          :'number-of-pages' => data[:number_of_pages],
          issued:            parse_date( data[:publish_date] ),
          URL:               data[:url],
          publisher:         data[:publishers] && data[:publishers].first[:name],
          cover:             data[:cover] && (data[:cover][:small] || data[:cover][:mdeium] || data[:cover][:large]),
          subject:           parse_data_subjects(data),
          author:            parse_data_authors(data, details),
          type:              'book'
      }.compact
    end

    def parse_data_subjects(data)
      subjects = Array(data[:subjects]) + Array(data[:subject_places]) + Array(data[:subject_people]) + Array(data[:subject_times])
      subjects.map { |i| i[:name]}.compact.uniq.presence
    end

    def parse_data_authors(data, details)
      authors = Array( data[:authors] || details[:authors] )
      authors.map { |i| {literal:i[:name]} }.presence
    end

    def parse_date(string)
      # For now we don't do any parsing but we might need to in future
      string &&  {literal:string}
    end

  end
end
