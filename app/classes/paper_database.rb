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

class PaperDatabase

  attr_reader :results

  def self.analyze!(search_query, limit=500)
    Rails.logger.info("Searching for #{search_query.inspect}")
    matching = Plos::Api.search(search_query, query_type:"subject", rows:limit)
    Rails.logger.info("Found #{matching.count} results")
    matching_dois = matching.map { |r| r['id'] }

    database = self.new

    matching_dois.each do |doi|
      Rails.logger.info("Fetching #{doi} ...")
      xml = Plos::Api.document( doi )
      Rails.logger.info("Parsing #{doi} ...")
      info= PaperParser.parse_xml(xml)
      database.add_paper(doi, info)
    end

    Rails.logger.info("Completed Analysis")
    database.results
  end

  def initialize
    @results = {
        match_count: 0,
        matches:     [],
        failures:    [],
        cited_count: 0,
    }
  end

  def add_paper(paper_doi, paper_info)
    # Rails.logger.debug(paper_info.inspect)

    @results[:match_count] += 1
    @results[:matches] << paper_doi

    if PaperParser.is_failure?(paper_info)
      add_failure(paper_doi)
    else
      add_references(paper_doi, paper_info, paper_info[:references])
    end
  end

  def results
    if @recalculate

      @results[:citations].each do |id, info|
        recalculate_results(info)
      end

      sort_results
      @recalculate = false
    end

    @results.delete(:failures) if @results[:failures].empty?

    @results
  end

  private

  def add_failure(paper_doi)
    @results[:failures] << paper_doi
  end

  def add_references(citing_doi, paper_info, all_references)
    @results[:citations] ||= {}

    all_references.each do |cited_ref_id, cited_ref|
      cited_ref_id  = cited_ref_id.to_s
      cited_id      = full_identifier(cited_ref)
      next unless cited_id

      add_reference(all_references, cited_id, cited_ref_id, cited_ref, citing_doi, paper_info)
    end

    @recalculate = true
  end

  def add_reference(all_references, cited_id, cited_ref_id, cited_ref, citing_doi, paper_info)
    cited_info                        = cited_info_by_id(cited_id)

    # cited_info[:ref_id              ||= id
    cited_info[:citations]            += 1
    cited_info[:bibliographic]                  = cited_ref[:bibliographic] unless cited_info[:bibliographic]
    cited_info[:intra_paper_mentions] += cited_ref[:mentions].to_i

    citing_info                            = new_citing_info(cited_ref)
    cited_info[:citing_papers][citing_doi] = citing_info
    cited_info[:self_citations]            = cited_ref[:self_citations]

    if cited_ref[:zero_mentions]
      cited_info[:zero_mentions] ||= []
      cited_info[:zero_mentions] << citing_doi
    end

    groups = cited_ref[:citation_groups]
    if groups.present?
      add_co_citation_counts(cited_ref_id, groups, cited_info, all_references)
      add_section_summaries(groups, cited_info)

      add_citing_groups(groups, citing_info, paper_info)
    end

    cited_info.compact!
  end

  def cited_info_by_id(id)
    unless @results[:citations][ id ]
      @results[:citations][ id ] = {
        intra_paper_mentions: 0,
        citations:            0,
        citing_papers:        {},
        sections:             {},
        co_citation_counts:   {},
      }
      @results[:cited_count] += 1
    end

    @results[:citations][ id ]
  end

  def new_citing_info(ref)
    info = {
        mentions: ref[:mentions].to_i,
        # median_co_citations: ref[:median_co_citations].to_i,
    }
    info[:zero_mentions] = true if ref[:zero_mentions]

    info
  end

  def add_citing_groups(groups, citing_info, paper_info)
    citations = citing_info[:citations] ||= []

    groups.each do |group|
      citations << {
          citing_id:     full_identifier(paper_info),
          section:       group[:section],
          word_position: "#{group[:word_position]}/#{paper_info[:paper][:word_count]}",
          context:       group[:context],
      }
    end

  end

  def add_section_summaries(groups, cited_info)
    sections  = cited_info[:sections]

    groups.each do |group|
      # Aggregate section counts
      section = group[:section]
      sections[section] = sections[section].to_s.to_i + 1
    end
  end

  def add_co_citation_counts(cited_ref_id, groups, cited_info, all_references)
    co_citation_counts = cited_info[:co_citation_counts]

    groups.each do |group|

      # Aggregate co-citation counts
      group[:references].each do |co_citation_id|
        next if co_citation_id == cited_ref_id

        cc_ref = all_references[co_citation_id] || all_references[co_citation_id.to_s.to_sym]
        co_citation_id = full_identifier(cc_ref) || 'No-Identifier'
        co_citation_counts[co_citation_id] = co_citation_counts[co_citation_id].to_i + 1
      end

    end
  end

  def recalculate_results(info)
  end

  def sort_results
    @results[:citations] = @results[:citations].sort.to_h
    @results[:citations].each do |id, cited_info|
      cited_info[:citing_papers] = cited_info[:citing_papers].sort.to_h
    end

    # Don't sort these - matches are sorted by relevance
    # @results[:matches].sort!
  end

  def full_identifier(ref)
    ref[:uri_type] ? "#{ref[:uri_type].downcase}:#{ref[:uri]}" : nil
  end

end
