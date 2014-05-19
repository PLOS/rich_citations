module Processors
  class Paper < Base
    include Helpers

    def process
      result[:paper] ||= {}
      result[:paper][:word_count] = word_count
    end

    protected

    def word_count
      XmlUtilities.text(body).word_count
    end

  end
end