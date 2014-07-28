module IdentifierResolvers
  class ArxivFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node)
        set_result(id, info)
      }
    end

    private

    def extract_info(node)
      # Try and extract the doi from the nodes
      # There are lots of corner cases here. This is just a start
      is_arxiv = /arxiv/i =~ node.node.at_css('source').try(:text)
      if is_arxiv
        id = id || Id::Arxiv.id( node.node.at_css('volume').try(:text))
        id = id || Id::Arxiv.id( node.node.at_css('fpage').try(:text))
        id = id || Id::Arxiv.id( node.node.at_css('volume').try(:text).to_s + '.' + node.node.at_css('fpage').try(:text).to_s)
      end

      # Try and extract the link from pure XML
      id = id || Id::Arxiv.extract(node.node.to_xml)

      # Try and extract the DOI from the pure text
      id = id || Id::Arxiv.extract(node.text)

      return nil unless id.present?
      {
          id_source:  :ref,
          id:         id,
          id_type:    :arxiv,
      }
    end

  end
end