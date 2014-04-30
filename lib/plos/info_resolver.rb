class Plos::InfoResolver

  attr_reader :references
  attr_reader :results
  attr_reader :unresolved_indexes
  attr_reader :state

  def self.resolve(references)
    new(references).resolve
  end

  def initialize(references)
    @references = create_references_hash(references)
    @unresolved_indexes = @references.keys

    @state = {}
  end

  def resolve
    @results = {}

    run_all_resolvers

    # [#69951266] fixup_duplicates_for_all_keys

    @results
  end

  # key is hte name of the main/unique key
  def set_result(index, key, info)
    return unless info

    info[:score] ||= Plos::CrossRefResolver::MIN_CROSSREF_SCORE
    hash_author_names(info)
    # info[:text] = references[index][:text]

    unresolved_indexes.delete(index)
    results[index] = info

    # [#69951266] flag_duplicates_for_more_resolving(key, index, info[key])
  end

  def unresolved_references
    references.slice(*unresolved_indexes)
  end

  private

  def run_all_resolvers
    RESOLVERS.each { |resolver| resolver.resolve(self) }
  end

  def flag_duplicates_for_more_resolving(key, current_index, value)
    return false unless key && value

    found = false
    results.each do |index, result|
      if index != current_index && result && result[key] && result[key].casecmp(value)==0
        found = true
        unresolved_indexes << index
      end
    end

    if found
      unresolved_indexes << current_index
    end
  end

  def fixup_duplicates_for_all_keys
    DOCUMENT_KEYS.each{|key| fixup_duplicates_for_key(key)}
  end

  def fixup_duplicates_for_key(key)
    duplicates = find_duplicates_for_key(key)

    duplicates.each do |_, duplicate_indexes|
      best_index = best_result_index(duplicate_indexes)

      duplicate_indexes.each do |index|
        mark_as_duplicate(key, index, best_index) if index != best_index
      end

    end
  end

  def hash_author_names(info)
    return unless info[:authors]

    info[:authors].map! do |i|
       if i.is_a?(String)
         { fullname: i }
       else
         i
      end
    end
  end

  def mark_as_duplicate(key, index, duplicate_of)
    result = results[index]
    result[:duplicate_of] = duplicate_of
    result["_#{key}".to_sym] = result[key]
    result.delete(key)
  end

  def best_result_index(indexes)
    indexes.max_by { |index| results[index][:score] }
  end

  def find_duplicates_for_key(key)
    groups = results.group_by{|index, result| result[key] && result[key].downcase }
    groups.delete(nil)
    # Only keep those with duplicate
    groups.keep_if { |v, results| results.length > 1 }
    # Just keep the indexes
    groups = groups.map { |value, results| [value, results.map(&:first) ] }.to_h
  end

  def create_references_hash(references)
    references.map do |index, node|
      [index,
       Hashie::Mash.new(
           node: node,
           text: normalized_node_text(index, node)
       )
      ]
    end.to_h
  end

  def normalized_node_text(index, node)
    # node.text # This concatenates strings together
    text_nodes = node.xpath('.//text()').map(&:text)
    text = text_nodes.join(" ")
    clean_text = text.gsub(/\s+/, ' ').strip

    remove_index_from_text(index, clean_text)
  end

  # If the text starts with the index then remove it
  def remove_index_from_text(index, text)
    index = index.to_s+' '

    if text.start_with?(index)
      text[index.length..-1]
    else
      text
    end
  end

  DOCUMENT_KEYS = [
      :doi
  ]

  ALL_RESOLVERS = [
      Plos::CrossRefResolver,
      Plos::DoiResolver,
      Plos::LowScoreCrossRefResolver,
      Plos::FailResolver,     # When nothing else has worked
  ]

  TEST_RESOLVERS = [
      Plos::FailResolver,     # When nothing else has worked
  ]

  RESOLVERS = ALL_RESOLVERS

end