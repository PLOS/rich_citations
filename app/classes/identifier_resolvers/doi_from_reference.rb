module IdentifierResolvers
  class DoiFromReference < Base

    API_URL = 'http://doi.crossref.org/servlet/query'

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node.text)
        root.set_result(id, :doi, info)
      }
    end

    private

    def extract_info(text)
      doi = Plos::Doi.extract(text)

      return nil unless doi.present?
      {
          source: :ref,
          doi:    doi,
      }
    end

  end
end