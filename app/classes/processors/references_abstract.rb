# Add sections node

module Processors
  class ReferencesAbstract < Base
    include Helpers

    def process
      plos_references = references.values.select{ |ref| Plos::Doi.is_plos_doi?(ref[:doi]) }
      add_abstracts(plos_references) if plos_references.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    def add_abstracts(references)
      dois    = references.map { |ref| ref[:doi] }
      results = Plos::Api.search_dois(dois)

      results.each_with_index do |result, index|
        if result['abstract']
          info = references[index][:info] ||= {}
          info[:abstract] = result['abstract'].first.strip
        end
      end
    end

  end
end