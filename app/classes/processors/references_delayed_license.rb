module Processors

  # The web site to return references may take a while so
  # attempt to get references in ReferencesLicense and again here if they
  # weren't all retrieved

  class ReferencesDelayedLicense < ReferencesLicense

    DELAY_BETWEEN_LICENSE_REQUESTS = 2.seconds

    def process
      references = references_without_licenses
      return if references.blank?

      last = state.license_retrieved_time || timestamp
      delay = last + DELAY_BETWEEN_LICENSE_REQUESTS - timestamp

      sleep(delay) if (delay > 0)

      super
    end

    # Execute as late as possible to maximize the time between this and ReferencesLicense
    def self.priority
      100
    end

    def self.dependencies
      ReferencesLicense
    end

    protected

    def is_delayed?
      true
    end

  end
end