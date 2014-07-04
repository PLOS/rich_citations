# Add sections node

module Processors
  class ReferencesAbstract < Base
    include Helpers

    def process
      plos_references = references_for_type(:doi).select { |ref| Id::Doi.is_plos_doi?(ref[:id]) }
      plos_references_without_abstracts = plos_references.reject { |ref| ref[:info] && ref[:info][:abstract] }

      add_abstracts(plos_references_without_abstracts) if plos_references_without_abstracts.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    def add_abstracts(references)
      dois    = references.map{ |ref| ref[:id] }
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