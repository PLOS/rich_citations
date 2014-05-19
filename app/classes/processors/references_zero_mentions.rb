# Add sections node

module Processors
  class ReferencesZeroMentions < Base
    include Helpers

    def process
      references.each do |_, info|
        info[:zero_mentions] = has_zero_mentions(info)
      end
    end

    def self.dependencies
      [ ReferencesCitedGroups ]
    end

    protected

    def has_zero_mentions(ref_info)
      cited_groups = ref_info[:citation_groups]
      cited_groups.blank? ? true : nil
    end

  end
end