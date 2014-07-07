module Processors
  class Doi < Base

    def process
      doi = xml.at('article-id[pub-id-type=doi]').try(:content).try(:strip)
      result[:id_type] = :doi
      result[:id]      = doi
    end

  end
end