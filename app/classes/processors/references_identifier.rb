module Processors
  class ReferencesIdentifier < Base
    include Helpers

    def process
      references.each do |id, ref|
        info = identifier_for_reference[id]

        ref.merge!(
          info:     info,
          id:       info[:id],
          id_type: info[:id_type]
        ) if info

      end

    end

    def cleanup
      references.each do |id, ref|
        info = ref[:info]
        info.compact! if info
        ref.delete(:info) if info.blank?
      end
    end

    def self.dependencies
      References
    end

    protected

    def identifier_for_reference
      @identifier_for_reference ||= begin
        reference_nodes = references.map { |id, ref| [id, ref[:node]] }.to_h
        IdentifierResolver.resolve(reference_nodes)
      end
    end

  end
end