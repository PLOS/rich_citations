class ReferenceResolver

  attr_reader :references
  attr_reader :results
  attr_reader :unresolved_ids
  attr_reader :state

  def self.resolve(references)
    new(references).resolve
  end

  def initialize(references)
    @references = create_references_hash(references)
    @unresolved_ids = @references.keys

    @state = {}
  end

  def resolve
    @results = {}

    run_all_resolvers

    # [#69951266] fixup_duplicates_for_all_keys

    @results
  end

  # key is hte name of the main/unique key
  def set_result(id, key, info)
    return unless info

    info[:score] = Resolvers::CrossRef::MIN_CROSSREF_SCORE unless info.has_key?(:score)
    hash_author_names(info)
    # info[:text] = references[id][:text]

    unresolved_ids.delete(id)
    results[id] = info.compact

    # [#69951266] flag_duplicates_for_more_resolving(key, id, info[key])
  end

  def unresolved_references
    references.slice(*unresolved_ids)
  end

  private

  def run_all_resolvers
    self.class.resolvers.each { |resolver| resolver.resolve(self) }
  end

  def flag_duplicates_for_more_resolving(key, current_id, value)
    return false unless key && value

    found = false
    results.each do |id, result|
      if id != current_id && result && result[key] && result[key].casecmp(value)==0
        found = true
        unresolved_ids << id
      end
    end

    if found
      unresolved_ids << current_id
    end
  end

  def fixup_duplicates_for_all_keys
    DOCUMENT_KEYS.each{|key| fixup_duplicates_for_key(key)}
  end

  def fixup_duplicates_for_key(key)
    duplicates = find_duplicates_for_key(key)

    duplicates.each do |_, duplicate_ids|
      best_id = best_result_id(duplicate_ids)

      duplicate_ids.each do |id|
        mark_as_duplicate(key, id, best_id) if id != best_id
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

  def mark_as_duplicate(key, id, duplicate_of)
    result = results[id]
    result[:duplicate_of] = duplicate_of
    result["_#{key}".to_sym] = result[key]
    result.delete(key)
  end

  def best_result_id(ids)
    ids.max_by { |id| results[id][:score] }
  end

  def find_duplicates_for_key(key)
    groups = results.group_by{|id, result| result[key] && result[key].downcase }
    groups.delete(nil)
    # Only keep those with duplicate
    groups.keep_if { |v, results| results.length > 1 }
    # Just keep the ids
    groups = groups.map { |value, results| [value, results.map(&:first) ] }.to_h
  end

  def create_references_hash(references)
    references.map.with_index do | (id, node), i|
      [id,
       Hashie::Mash.new(
           node: node,
           text: normalized_node_text(node, i+1)
       )
      ]
    end.to_h
  end

  def normalized_node_text(node, index)
    clean_text = XmlUtilities.spaced_text(node)
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

  def self.resolvers
    ALL_RESOLVERS
  end

  DOCUMENT_KEYS = [
      :doi
  ]

  ALL_RESOLVERS = [
      Resolvers::CrossRef,
      Resolvers::Doi,
      Resolvers::LowScoreCrossRef,
      Resolvers::Fail,     # When nothing else has worked
  ]

  TEST_RESOLVERS = [
      Resolvers::Fail,     # When nothing else has worked
  ]

end