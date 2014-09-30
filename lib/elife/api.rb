module Elife
  module Api
    # Given the DOI of an elife paper, downloads the XML and parses it
    def self.document(doi)
      url = "http://dx.doi.org/#{doi}"
      redirect_count = 0
      redirects = []
      http = Net::HTTP::Persistent.new
      loop do
        uri = URI.parse(url)
        req = Net::HTTP::Head.new(uri.request_uri)
        puts url
        response = http.request uri, req

        location = response.header['location']
        if location
          raise "Recursive redirect" if redirects.include?(location)
          raise "Too many redirects" if redirect_count >= 3
          redirect_count += 1
          redirects << location
          url = location
        else
          # reached the end, fetch the XML
          response = Rails.cache.fetch("#{doi}_xml", :expires_in=> 108000) do
            HttpUtilities.get("#{url}.source.xml")
          end
          Loofah.xml_document(response)
        end
      end
    end
  end
end
