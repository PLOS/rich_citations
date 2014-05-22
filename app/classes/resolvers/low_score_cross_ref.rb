# Fills in non-results with low-scoring results from crossref

module Resolvers
  class LowScoreCrossRef < Base

    def resolve
      unresolved_ids = root.unresolved_ids
      crossref_infos = root.state[:crossref_infos]

      crossref_infos.each do |id, info|
        if ! root.results[id]
          info[:source] = :crossref_lowscore
          root.set_result(id, :doi, info)
        end
      end
    end

  end
end