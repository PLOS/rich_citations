# Add sections node

module Processors
  class ReferencesInfoCacheLoader < Base
    include Helpers

    def process
      load_cached_info if Rails.configuration.app.use_cached_info
    end

    def self.dependencies
      ReferencesIdentifier
    end

    protected

    def load_cached_info
      references.each do |id, ref|
        next unless ref[:doi] && ref[:info]

        cache = PaperInfoCache.find_by_identifier('doi', ref[:doi])
        ref[:info].reverse_merge!(cache.info) if cache
      end
    end

  end
end