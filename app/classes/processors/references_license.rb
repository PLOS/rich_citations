module Processors
  class ReferencesLicense < Base
    include Helpers

    def process
      references = references_without_licenses
      return if references.blank?

      results = get_licenses(references)
      add_licenses(results)
    end

    def self.dependencies
      [ ReferencesInfo ]
    end

    protected

    API_URL = 'http://howopenisit.org/lookup/12345,67890'

    def references_without_licenses
      references.select { |id, ref| ref[:doi] && ! ref[:info][:license] }.to_h
    end

    def get_licenses(references)
      data = references.map { |id,ref| {type:'doi', id:ref[:doi]} }
      results = Plos::Api.http_post(API_URL, JSON.generate(data),
                          'Accept' => Mime::JSON, 'Content-Type' => Mime::JSON
      )
      JSON.parse(results)
    end

    def add_licenses(results)
      Array(results['results']).each do |result|
        ref     = get_reference( result['identifier'] )
        license = get_license( result['license'] )
        next unless ref && license

        ref[:info][:license] = license['type']
      end
    end

    def get_reference(identifiers)
      identifiers.each do| identifier|
        ref = reference_by_identifier(identifier['id'])
        return ref if ref
      end
    end

    def get_license( licenses )
      valid_licenses = licenses.select { |license| license['status']=='active' }
      prioritized_licenses = valid_licenses.sort_by { |license| Time.parse( license['provenance']['date'] ) }
      prioritized_licenses.last
    end

  end
end