# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class IdentifierResolver

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
  def set_result(id, info)
    return unless info

    info[:score] = IdentifierResolvers::CrossRef::MIN_CROSSREF_SCORE unless info.has_key?(:score)
    # info[:text] = references[id][:text]

    unresolved_ids.delete(id)
    results[id] = info.compact

    # [#69951266] flag_duplicates_for_more_resolving(id, info)
  end

  def has_result?(id)
    results[id]
  end

  def unresolved_references
    references.slice(*unresolved_ids)
  end

  private

  def run_all_resolvers
    self.class.resolvers.each { |resolver| resolver.resolve(self) }
  end

  def flag_duplicates_for_more_resolving(current_id, info)
    return false unless info[:id_type] && info[:id]

    found = false
    results.each do |id, result|
      if id != current_id && result && result[:id_type]==info[:id_type] && info[:id].casecmp( result[:id] )==0
        found = true
        unresolved_ids << id
      end
    end

    if found
      unresolved_ids << current_id
    end
  end

  def fixup_duplicates_for_all_keys
    id_types = result.map { |id, result| result[:id_type]}.uniq
    id_types.each{|type| fixup_duplicates_for_types(type)}
  end

  def fixup_duplicates_for_types(type)
    duplicates = find_duplicates_for_type(type)

    duplicates.each do |_, duplicate_ids|
      best_id = best_result_id(duplicate_ids)

      duplicate_ids.each do |id|
        mark_as_duplicate(id, best_id) if id != best_id
      end

    end
  end

  def mark_as_duplicate(id, duplicate_of)
    result = results[id]
    result[:duplicate_of] = duplicate_of
    result[:_id_type] = result[:id_type]
    result.delete(:id_type)
  end

  def best_result_id(ids)
    ids.max_by { |id| results[id][:score] }
  end

  def find_duplicates_for_type(type)
    groups = results.
             select  {|id, result| r[:id_type] == type }.
             group_by{|id, result| result[:id] && result[:id].downcase }
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
           id:   id,
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

  ALL_RESOLVERS = [
      # IdentifierResolvers::CrossRef,
      # IdentifierResolvers::DoiFromReference,
      # IdentifierResolvers::IsbnFromReference,
      # IdentifierResolvers::PubmedidFromReference,
      # IdentifierResolvers::PmcidFromReference,
      # IdentifierResolvers::ArxivFromReference,
      # IdentifierResolvers::GithubFromReference,
      IdentifierResolvers::UrlFromReference,
      IdentifierResolvers::LowScoreCrossRef,
      IdentifierResolvers::Fail,     # When nothing else has worked
  ]

  TEST_RESOLVERS = [
      IdentifierResolvers::Fail,     # When nothing else has worked
  ]

end
