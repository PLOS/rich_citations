class Plos::DoiResolver < Plos::BaseResolver

  API_URL = 'http://doi.crossref.org/servlet/query'

  def resolve
    unresolved_dois = unresolved_references.map{ |index, text|
      doi = extract_doi(text)
      [index, doi] if doi
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
      index = unresolved_dois.keys[i]
      info  = extract_info(result)
      root.set_result(index, info)
    end
  end

  # (^|\s)doi:?\s*(?<result>10\.([[:punct:]]*[^[[:punct:]][[:space:]]]+)+)

  DOI_PREFIX_REGEX = /(^|\s)doi:?\s*(?<result>10\.\S+(?<!#{Plos::Utilities::PUNCT}))/io
  DOI_URL_REGEX    = /(^|\W)doi\.org\/(?<result>10\.\S+(?<!#{Plos::Utilities::PUNCT}))/io
  DOI_ALONE_REGEX  = /^(#{Plos::Utilities::PUNCT}|\s)+(?<result>10\.\S+(?<!#{Plos::Utilities::PUNCT}))/io

  def self.extract_doi(text)
    Plos::Utilities.match_regexes(text, { DOI_URL_REGEX    => true,
                                          DOI_PREFIX_REGEX => false,
                                          DOI_ALONE_REGEX  => false  })
  end

  def extract_doi(text)
    self.class.extract_doi(text)
  end

  private


  DOI_KEY_MAP = {
      'doi'        => 'journal_article doi_data doi',
      'journal'    => 'journal_metadata full_title',
      'issn'       => 'journal_metadata issn[media_type=print]',
      'title'      => 'journal_article titles title',
      'year'       => 'journal_issue publication_date year',
      'volume'     => 'journal_issue journal_volume volume',
      'issue'      => 'journal_issue issue',
      'start_page' => 'journal_article pages first_page',
      'end_page'   => 'journal_article pages last_page',
      'authors[]'  => 'journal_article contributors person_name[contributor_role=author]',
  }

  def extract_info(result)
    journal = result.css('crossref journal')
    return nil unless journal

    info = {
        source: :doi
    }

    DOI_KEY_MAP.each do |key, selector|
      matches = journal.css(selector)
      next unless matches.present?

      matches.each do |match|
        value = cleanup_node(match)
        next if value.blank?
        Rack::Utils.normalize_params(info, key, value)
      end
    end

    info.symbolize_keys!
  end

  def cleanup_node(node)
    text = node.text.strip
    text.gsub(/\s+/,' ')
  end

end