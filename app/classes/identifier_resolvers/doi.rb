module IdentifierResolvers
  class Doi < Base

    API_URL = 'http://doi.crossref.org/servlet/query'

    def resolve
      unresolved_dois = unresolved_references.map{ |id, node|
        doi = Plos::Doi.extract(node.text)
        [id, doi] if doi
      }.compact.to_h
      return if unresolved_dois.empty?

      dois   = unresolved_dois.values.join("\n")
      params = {format: "unixref", pid:Rails.configuration.app.crossref_pid }
      params = URI.encode_www_form(params)
      body   = URI.encode_www_form(qdata:dois)
      # This isn't actually documented, actually nothing is, but I'm using
      # a post here instead of a get so that it can handle longer lists
      response = Plos::Api::http_post(API_URL+'?' + params, body)
      results = Nokogiri::XML(response).css('doi_records doi_record')

      results.each_with_index do |result, i|
        id    = unresolved_dois.keys[i]
        info  = extract_info(result)
        root.set_result(id, :doi, info)
      end
    end

    private

    def extract_info(result)
      journal = result.css('crossref journal')
      return nil unless journal.present?

      doi = journal.css('journal_article doi_data doi')
      return nil unless doi.present?

      {
          source: :doi,
          doi:    cleanup_node(doi.first),
      }
    end

    def cleanup_node(node)
      text = node.text.strip
      text.gsub(/\s+/,' ')
    end

  end
end