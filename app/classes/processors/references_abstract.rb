# Add sections node

module Processors
  class ReferencesAbstract < Base
    include Helpers

    def process
      plos_references = references.values.select{ |ref| Plos::Doi.is_plos_doi?(ref[:doi]) }
      add_abstracts(plos_references) if plos_references.present?
    end

    def self.dependencies
      [ReferencesInfo]
    end

    protected

    def add_abstracts(references)
      results = fetch_abstracts(references)

      results.each_with_index do |result, index|
        if result['abstract']
          info = references[index][:info] ||= {}
          info[:abstract] = result['abstract'].first.strip
        end
      end
    end

    def fetch_abstracts(references)
      dois = references.map { |ref| ref[:doi] }
      dois = dois.map { |doi| %("#{URI.encode_www_form_component(doi)}") }
      query = "q=id:(#{dois.join('+OR+')})"
      url = Plos::Api::SEARCH_URL + "?rows=#{references.count}&wt=json&api_key=#{Rails.configuration.app.plos_api_key}"

      response = Plos::Api.http_post(url,
                                     query,
                                     'Accept'       => 'application/json',
                                     'Content-Type' => 'application/x-www-form-urlencoded')
      json = JSON.parse(response)
      json['response']['docs']
    end

  end
end