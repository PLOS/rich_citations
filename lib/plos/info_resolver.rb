class Plos::InfoResolver

  attr_reader :references
  attr_reader :results
  attr_reader :unresolved_indexes

  def self.resolve(references)
    new(references).resolve
  end

  def initialize(references)
    @references = references
  end

  def resolve
    @results = {}
    @unresolved_indexes = @references.keys

    run_resolvers

    @results
  end

  def set_result(index, info)
    return unless info

    unresolved_indexes.delete(index)
    results[index] = info
  end

  def unresolved_references
    references.slice(*unresolved_indexes)
  end

  private

  def run_resolvers
    RESOLVERS.each { |resolver| resolver.resolve(self) }
  end

  RESOLVERS = [
      Plos::CrossRefResolver,
      Plos::DoiResolver,
  ]

end