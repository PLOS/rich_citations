module Processors
  class ReferencesInfo < Base
    include Helpers

    def process
      references.each do |index, ref|
        info = info_for_reference[index]

        ref[:info] = info
        ref[:doi]  = info && info[:doi]
      end

    end

    def self.dependencies
      References
    end

    protected

    def info_for_reference
      reference_nodes = references.map { |index, ref| [index, ref[:node]] }.to_h
      @info_for_reference ||= ReferenceResolver.resolve(reference_nodes)
    end

  end
end