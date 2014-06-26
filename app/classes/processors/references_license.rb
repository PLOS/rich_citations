module Processors
  class ReferencesLicense < Base
    include Helpers

    def process
      references = references_without_licenses
      return if references.blank?

      results = get_licenses(references)
      add_licenses(results)

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

    API_URL = 'http://howopenisit.org/lookup/12345,67890'

    def is_delayed?
      false
    end

    def timestamp
      Time.now
    end

    def references_without_licenses
      references.select { |id, ref| ref[:doi] && ! ref[:info][:license] }.to_h
    end

    def get_licenses(references)
      data = references.map { |id,ref| {type:'doi', id:ref[:doi]} }
      results = HttpUtilities.post(API_URL, JSON.generate(data),
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
      prioritized_licenses = licenses.sort_by { |license|
        date = Time.parse( license['provenance']['date'] )
        # Prioritize active licenses
        license['status']=='active' ? date : date - 1000.years
      }
      prioritized_licenses.last
    end

  end
end