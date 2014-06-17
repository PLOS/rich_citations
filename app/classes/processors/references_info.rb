require 'uri'

module Processors
  class ReferencesInfo < Base
    include Helpers

    def process
      references.each do |id, ref|
        next if ref[:info].try(:[], :type)

        doi = ref[:doi]
        get_doi_info(doi, ref) if doi
      end
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    # cf http://www.crosscite.org/cn/
    # This API always does a redirect. If we can guess the source ebfore hand we could optimize slightly
    # see Pivotal #72716068

    def get_doi_info(doi, ref)
      result = get_result(doi)
      result = result.except(:DOI, :source, :score)
      ref[:info].merge!(result)
    end

    def get_result(doi)
      begin
        json   = Plos::Api.http_get("http://dx.doi.org/#{URI.encode_www_form_component(doi)}", 'application/citeproc+json')
        JSON.parse(json, symbolize_names:true)
      rescue Exception=>ex
        Rails.logger.error(ex)
        return {}
      end
    end

  end
end
