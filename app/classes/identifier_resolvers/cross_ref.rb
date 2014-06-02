module IdentifierResolvers
  class CrossRef < Base

    # cf  http://search.crossref.org/help/api#match
    API_URL = 'http://search.crossref.org/links'

    def resolve
      unresolved_texts = unresolved_references.map { |id, data| [id, data.text] }.to_h
      @crossref_infos = root.state[:crossref_infos] = {}
      unresolved_texts.each_slice(50) do |group| resolve_group(group.to_h) end
    end

    private

    # Results with a lower score from the crossref.org will be ignored
    MIN_CROSSREF_SCORE = 2.5 #@TODO: Keeping this value high to force skips for testing

    CROSSREF_KEY_MAP = {
        'rft.atitle'  => 'title',
        'rft.jtitle'  => 'journal',
        'rft.date'    => 'year',
        'rft.volume'  => 'volume',
        'rft.issue'   => 'issue',
        'rft.spage'   => 'start_page',
        'rft.epage'   => 'end_page',
        'rft.aufirst' => 'first_author[first_name]',
        'rft.aulast'  => 'first_author[last_name]',
        'rft.au'      => 'authors[]',
    }

    def resolve_group(references)
      texts    = JSON.generate( references.values )
      response = Plos::Api::http_post(API_URL, texts, :xml)
      results  = JSON.parse(response)['results']

      results.each_with_index do |result, i|
        id    = references.keys[i]
        info  = extract_info(result)
        next unless info

        @crossref_infos[id] = info
        root.set_result(id, :doi, info) if include_info?(info)

      end
    end

    def include_info?(info)
      info && info[:score] && info[:score] >= MIN_CROSSREF_SCORE
    end

    def extract_info(result)
      self.class.extract_info(result)
    end

    def self.extract_info(result)
      return unless result['match']

      info = {
          source: :crossref,
          doi:    Plos::Doi.extract( result['doi'] ),
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
end