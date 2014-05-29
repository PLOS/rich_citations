module Processors
  class Base

    attr_reader :xml, :result

    def initialize(xml, result)
      @xml    = xml
      @result = result
    end

    def process
      raise "Please implement me"
    end

    def cleanup
      # nothing
    end

    # lower priority execute sooner
    def self.priority
      50
    end

    def self.dependencies
     nil
    end

  end
end