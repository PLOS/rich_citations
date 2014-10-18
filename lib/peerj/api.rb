module Peerj
  module Api
    # Given the DOI of a PeerJ paper, downloads the XML and parses it
    def self.document(doi)
      number = doi.match(/([0-9]+)$/)[-1]
      response = Rails.cache.fetch("#{doi}_xml", expires_in: 108_000) do
        HttpUtilities.get("https://peerj.com/articles/#{number}.xml")
      end
      Loofah.xml_document(response)
    end
  end
end
