module IdentifierResolvers
  class DoiFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node)
        set_result(id, info)
      }
    end

    private

    def extract_info(node)
      #Try and extract the doi from the ext-link node
      link = node.node.at_css('ext-link[ext-link-type=doi]')
      doi = link && Id::Doi.extract( link['xlink:href'] )

      # Try and extract the link from pure XML
      doi = doi || Id::Doi.extract(node.node.to_xml)

      # Try and extract the DOI from the pure text
      doi = doi || Id::Doi.extract(node.text, true)

      return nil unless doi.present?
      {
          id_source:  :ref,
          id:         doi,
          id_type:    :doi,
      }
    end

  end
end