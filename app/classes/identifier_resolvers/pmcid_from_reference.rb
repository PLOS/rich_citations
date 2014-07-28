module IdentifierResolvers
  class PmcidFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node.text)
        set_result(id, info)
      }
    end

    private

    def extract_info(text)
      id = Id::Pmcid.extract(text)

      return nil unless id.present?
      {
          id_source:  :ref,
          id:         id,
          id_type:    :pmcid,
      }
    end

  end
end