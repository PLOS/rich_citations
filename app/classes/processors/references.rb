module Processors
  class References < Base
    include Helpers

    def process

      references = result[:references] = {}

      reference_nodes.each do |index, node|

        reference   = {
            id:   node[:id],
            node: node,       # for other processors
        }

        references[index] = reference
      end

    end

    def cleanup
      references.each do |index, ref|
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