module Processors
  class References < Base
    include Helpers

    def process

      references = {}

      reference_nodes.each do |index, ref|
        info = info_for_reference[index]

        reference   = {
            id:   ref[:id],
            info: info,
            doi:  info && info[:doi],
        }

        references[index] = reference
      end

      result[:references] = references
    end

    def cleanup
      references.each do |index, ref|
        ref.compact!
      end
    end

    protected

    def info_for_reference
      @info_for_reference ||= ReferenceResolver.resolve(reference_nodes)
    end

    def reference_nodes
      @reference_nodes ||= begin
        xml.css('ref-list ref').map.with_index{ |n,i| [i+1, n] }.to_h
      end
    end

  end
end