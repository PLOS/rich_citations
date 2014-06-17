module Processors
  class ReferencesCrossmark < Base
    include Helpers

    def process
      references.each do |id, ref|
        next if ref[:updated_by]
        doi = ref[:doi]
        get_crossmark_info(doi, ref) if doi
      end
    end

    def self.dependencies
      ReferencesIdentifier
    end

    protected

    def get_crossmark_info(doi, ref)
      begin
        result = get_result(doi)
        ref[:updated_by] = result[:updated_by]
      rescue Net::HTTPServerException
        # most likely a 404, ignore
      end
    end

    def get_result(doi)
      json   = Plos::Api.http_get("http://crossmark.crossref.org/crossmark/?doi=#{URI.encode_www_form_component(doi)}")
      JSON.parse(json, symbolize_names:true)
    end
  end
end
