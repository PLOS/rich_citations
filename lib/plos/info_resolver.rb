class Plos::InfoResolver

  attr_reader :references
  attr_reader :results
  attr_reader :unresolved_indexes

  def self.resolve(references)
    new(references).resolve
  end

  def initialize(references)
    @references = references.map do |index, node|
      [index,
       Hashie::Mash.new(
         node: node,
         text: normalized_node_text(index, node)
       )
      ]
    end.to_h
    @unresolved_indexes = @references.keys
  end

  def resolve
    @results = {}

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

  def normalized_node_text(index, node)
    # node.text # This concatenates strings together
    text_nodes = node.xpath('.//text()').map(&:text)
    text = text_nodes.join(" ")
    clean_text = text.gsub(/\s+/, ' ').strip

    remove_index(index, clean_text)
  end

  # If the text starts with the index then remove it
  def remove_index(index, text)
    index = index.to_s+' '

    if text.start_with?(index)
      text[index.length..-1]
    else
      text
    end
  end

  RESOLVERS = [
      Plos::CrossRefResolver,
      Plos::DoiResolver,
      Plos::FailResolver,     # When nothing else has worked
  ]

end