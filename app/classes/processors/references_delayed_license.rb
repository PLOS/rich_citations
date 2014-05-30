module Processors

  # The web site to return references may take a while so
  # attempt to get references in ReferencesLicense and again here if they
  # weren't all retrieved

  class ReferencesDelayedLicense < ReferencesLicense

    # def process
    #   super
    # end

    # Execute as late as possible to maximize the time between this and ReferencesLicense
    def self.priority
      100
    end

    def self.dependencies
      ReferencesLicense
    end

  end
end