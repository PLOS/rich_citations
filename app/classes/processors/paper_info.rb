module Processors
  class PaperInfo < Base
    include Helpers

    def process
      paper = result[:paper] ||= {}
      paper[:title]      = xml.at('article-meta article-title').try(:content).try(:strip)
      paper[:word_count] = word_count
    end

    def cleanup
      result[:paper].compact!
    end

    protected

    def word_count
      XmlUtilities.text(body).word_count
    end

  end
end