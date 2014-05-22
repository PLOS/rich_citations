module Processors
  class ReferencesInfo < Base
    include Helpers

    def process
      references.each do |id, ref|
        info = info_for_reference[id]

        ref[:info] = info
        ref[:doi]  = info && info[:doi]
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

    def info_for_reference
      reference_nodes = references.map { |id, ref| [id, ref[:node]] }.to_h
      @info_for_reference ||= ReferenceResolver.resolve(reference_nodes)
    end

  end
end