module IdentifierResolvers
  class CrossRef < Base
    SLICE_SIZE=50
    
    # cf  http://search.crossref.org/help/api#match
    API_URL = 'http://search.crossref.org/links'

    def resolve
      unresolved_texts = unresolved_references.map { |id, data| [id, data.text] }.to_h
      @crossref_infos = state[:crossref_infos] = {}
      unresolved_texts.each_slice(SLICE_SIZE) do |group|
        # if it failed, try each individual item
        if !resolve_group(group.to_h) then
          group.each do |r|
            resolve_group([r].to_h)
          end
        end
      end
    end

    private

    # Results with a lower score from the crossref.org will be ignored
    MIN_CROSSREF_SCORE = 2.5 #@TODO: Keeping this value high to force skips for testing

    def resolve_group(references)
      texts    = JSON.generate( references.values )
      response = HttpUtilities.post(API_URL, texts, :xml)
      response_json = JSON.parse(response)
      if (!response_json['query_ok']) then
        return false
      else
        results  = response_json['results']
        results.each_with_index do |result, i|
          id    = references.keys[i]
          info  = extract_info(result)
          next unless info
          
          @crossref_infos[id] = info
          set_result(id, info) if include_info?(info)
        end
        return true
      end
    end

    def include_info?(info)
      info && info[:score] && info[:score] >= MIN_CROSSREF_SCORE
    end

    def extract_info(result)
      self.class.extract_info(result)
    end

    def self.extract_info(result)
      return nil unless result['match']
      doi = Id::Doi.extract( result['doi'] )
      return nil unless doi.present?

      {
          id_source:   :crossref,
          id:          doi,
          id_type:     :doi,
          score:       result['score'].to_f,
      }
    end

  end
end