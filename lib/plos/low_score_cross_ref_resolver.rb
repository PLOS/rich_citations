# Fills in non-results with low-scoring results from crossref

class Plos::LowScoreCrossRefResolver < Plos::BaseResolver

  def resolve
    unresolved_indexes = root.unresolved_indexes
    results = root.state[:crossref_results]

    results.each_with_index do |result, i|
      index = i + 1 # This assumes that the CrossRefResolver was first and indexes match
      if ! root.results[index]
        info  = extract_info(result)
        root.set_result(index, :doi, info)
      end
    end
  end

  private

  def extract_info(result)
    result = Plos::CrossRefResolver.extract_info(result)
    result[:source] = :crossref_lowscore if result
    result
  end

end