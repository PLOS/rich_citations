module Processors
  class ReferencesInfo < Base
    include Helpers

    def process
      references.each do |id, ref|
        doi = ref[:doi]
        get_doi_info(doi, ref) if doi
      end
    end

    def self.dependencies
      ReferencesIdentifier
    end

    protected

    # cf http://www.crosscite.org/cn/

    def get_doi_info(doi, ref)
      json   = Plos::Api.http_get("http://dx.doi.org/#{doi}", 'application/citeproc+json')
      result = JSON.parse(json, symbolize_names:true)
      result = result.except(:DOI, :source, :score)
      ref[:info].merge!(result)
    end

  end
end