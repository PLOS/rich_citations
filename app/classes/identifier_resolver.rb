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

  attr_reader :citing_uri
  attr_reader :references
  attr_reader :results
  attr_reader :unresolved_ids
  attr_reader :state

  def self.resolve(citing_uri, references)
    new(citing_uri, references).resolve
  end

  def initialize(citing_uri, references)
    @citing_uri = citing_uri
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
    return false unless info[:uri_type] && info[:uri]

    found = false
    results.each do |id, result|
      if id != current_id && result && result[:uri_type]==info[:uri_type] && info[:uri].casecmp( result[:uri] )==0
        found = true
        unresolved_ids << id
      end
    end

    if found
      unresolved_ids << current_id
    end
  end

  def fixup_duplicates_for_all_keys
    uri_types = result.map { |id, result| result[:uri_type]}.uniq
    uri_types.each{|type| fixup_duplicates_for_types(type)}
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
    result[:_uri_type] = result[:uri_type]
    result.delete(:uri_type)
  end

  def best_result_id(ids)
    ids.max_by { |id| results[id][:score] }
  end

  def find_duplicates_for_type(type)
    groups = results.
             select  {|id, result| r[:uri_type] == type }.
             group_by{|id, result| result[:uri] && result[:uri].downcase }
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
           text: XmlUtilities.spaced_text(node)
       )
      ]
    end.to_h
  end

  def self.resolvers
    ALL_RESOLVERS
  end

  ALL_RESOLVERS = [
      IdentifierResolvers::DoiFromPlosHtml,
      # disabled to see if that improves performance - everything *should* be available from HTML -egh
      # IdentifierResolvers::CrossRef,
      IdentifierResolvers::DoiFromReference,
      IdentifierResolvers::IsbnFromReference,
      IdentifierResolvers::PubmedidFromReference,
      IdentifierResolvers::PmcidFromReference,
      IdentifierResolvers::ArxivFromReference,
      IdentifierResolvers::GithubFromReference,
      IdentifierResolvers::WikipediaFromReference,  # runs before UrlFromReference
      IdentifierResolvers::UrlFromReference,
      IdentifierResolvers::LowScoreCrossRef,
      IdentifierResolvers::Fail,     # When nothing else has worked
  ]

  TEST_RESOLVERS = [
      IdentifierResolvers::Fail,     # When nothing else has worked
  ]

end
