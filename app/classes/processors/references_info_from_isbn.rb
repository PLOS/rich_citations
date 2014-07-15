require 'uri'

module Processors
  class ReferencesInfoFromIsbn < Base
    include Helpers

    def process
      # Process in groups since IDs have to fit in a URL
      references_without_info.each_slice(10) do |references|
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

    def references_without_info
      references_for_type(:isbn).reject { |ref| ref[:info] && ref[:info][:source] }
    end

    def fill_info_for_references(references)
      references = references.map { |ref| [ "ISBN:#{ref[:id]}", ref]}.to_h

      results = fetch_results_for_ids(references.keys)

      results.each do |id, result|
        info = convert_result_to_info(result)
        references[id][:info] ||= {}
        references[id][:info].merge!(info)
      end
    end

    def fetch_results_for_ids(ids)
      url    = API_URL + ids.join('|')
      json   = HttpUtilities.get(url, :json)
      JSON.parse(json, symbolize_names:false)
    end

    def convert_result_to_info(result)
      result.symbolize_keys_recursive!
      data    = (result[:records] && result[:records].values.first[:data])    || {}
      details = (result[:records] && result[:records].values.first[:details].try(:[], :details) ) || {}

      {
          source:            'OpenLibrary',
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
