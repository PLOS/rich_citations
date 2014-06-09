module Processors
  class State < Base

    def process
      # Nothing
    end

    def cleanup
      result.delete(:state)
    end

    def self.priority
      0
    end

  end
end