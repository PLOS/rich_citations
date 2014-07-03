module IdentifierResolvers
  class IsbnFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node.text)
        set_result(id, :isbn, info)
      }
    end

    private

    def extract_info(text)
      isbn = Id::Isbn.extract(text)

      return nil unless isbn.present?
      {
          source: :ref,
          isbn:   isbn,
      }
    end

  end
end