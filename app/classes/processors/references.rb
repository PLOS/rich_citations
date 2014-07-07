module Processors
  class References < Base
    include Helpers

    def process

      references = result[:references] = {}

      reference_nodes.each do |index, node|
         id = node[:id]

        reference   = {
            ref_id: id,
            index:  index,
            node:   node,       # for other processors
        }

        references[id] = reference
      end

    end

    def cleanup
      references.each do |id, ref|
        ref.delete(:node)
        ref.compact!
      end
    end

    protected

    def reference_nodes
      @reference_nodes ||= begin
        xml.css('ref-list ref').map.with_index{ |n,i| [i+1, n] }.to_h
      end
    end

  end
end