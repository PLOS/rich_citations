class Plos::CrossRefResolver

  # Results with a lower score from the crossref.org will be ignored
  MIN_CROSSREF_SCORE = 1

  def self.resolve(references)
    new(references).resolve
  end

  def initialize(references)
    @references = references
  end

  def resolve
    @cross_refs = {}
    @unresolved_indexes = @references.keys

    search_crossref

    @cross_refs
  end

  private

  attr_reader :references
  attr_reader :cross_refs
  attr_reader :unresolved_indexes

  def unresolved_references
    references.slice(*unresolved_indexes)
  end

  def set_crossref(index, crossref)
    return unless crossref

    unresolved_indexes.delete(index)
    cross_refs[index] = crossref
  end

  CROSSREF_URL = 'http://search.crossref.org/links'

  # cf  http://search.crossref.org/help/api#match
  def search_crossref
    unresolved = unresolved_references
    return if unresolved_references.empty?

    texts = JSON.generate( unresolved_references.values )
    response = Plos::Api::http_post(CROSSREF_URL, texts, :xml)
    json = JSON.parse(response)

    json['results'].map.with_index do |result, i|
      index = unresolved.keys[i]
      set_crossref index, extract_crossref_info(result)
    end
  end

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

  def extract_crossref_info(ref)
    return nil unless ref['match']
    return nil unless ref['score'] > MIN_CROSSREF_SCORE

    crossref = {
        source: :crossref,
        doi:    Plos::Utilities.extract_doi( ref['doi'] ),
        score:  ref['score'].to_f,
    }

    coins = ref['coins'].to_s.gsub('&amp;', '&')
    coins.split('&').each do |p|
      k, v = p.split('=', 2)
      k = CROSSREF_KEY_MAP[k]

      if k
        v = Rack::Utils.unescape(v).strip
        Rack::Utils.normalize_params(crossref, k, v)
      end

    end

    crossref.symbolize_keys!
  end

end