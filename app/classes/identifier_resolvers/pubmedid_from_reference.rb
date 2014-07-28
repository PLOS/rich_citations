module IdentifierResolvers
  class PubmedidFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node.text)
        set_result(id, info)
      }
    end

    private

    def extract_info(text)
      id = Id::Pmid.extract(text)

      return nil unless id.present?
      {
          id_source:  :ref,
          id:         id,
          id_type:    :pmid,
      }
    end

  end
end