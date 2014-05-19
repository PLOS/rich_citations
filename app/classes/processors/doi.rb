module Processors
  class Doi < Base

    def process
      doi = xml.at('article-id[pub-id-type=doi]').try(:content).try(:strip)
      result[:doi] = doi
    end

  end
end