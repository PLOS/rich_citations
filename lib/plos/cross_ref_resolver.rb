class Plos::CrossRefResolver < Plos::BaseResolver

  # cf  http://search.crossref.org/help/api#match
  API_URL = 'http://search.crossref.org/links'

  def resolve
    return if unresolved_references.empty?

    texts = JSON.generate( unresolved_references.values )
    response = Plos::Api::http_post(API_URL, texts, :xml)
    results = JSON.parse(response)['results']

    results.each_with_index do |result, i|
      index = unresolved_references.keys[i]
      info  = extract_info(result)
      root.set_result(index, info)
    end
  end

  private

  # Results with a lower score from the crossref.org will be ignored
  MIN_CROSSREF_SCORE = 3.0 #@TODO: Keeping this value low to force skips for testing

  CROSSREF_KEY_MAP = {
      'rft.atitle' => 'title',
      'rft.jtitle' => 'journal',
      'rft.date'   => 'year',
      'rft.volume' => 'volume',
      'rft.issue'  => 'issue',
      'rft.spage'  => 'start_page',
      'rft.epage'  => 'end_page',
      'rft.au'     => 'authors[]',
  }

  def extract_info(result)
    return nil unless result['match']
    return nil unless result['score'] >= MIN_CROSSREF_SCORE

    info = {
        source: :crossref,
        doi:    Plos::DoiResolver.extract_doi( result['doi'] ),
        score:  result['score'].to_f,
    }

    coins = result['coins'].to_s.gsub('&amp;', '&')
    coins.split('&').each do |coin|
      key, value = coin.split('=', 2)
      key = CROSSREF_KEY_MAP[key]

      if key
        value = Rack::Utils.unescape(value).strip
        Rack::Utils.normalize_params(info, key, value)
      end

    end

    info.symbolize_keys!
  end

end