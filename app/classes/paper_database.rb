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
      info= PaperParser.parse(xml)
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

      @results[:citations].each do |doi, info|
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

    all_references.each do |cited_num, cited_ref|
      cited_num = cited_num.to_s.to_i
      cited_doi = cited_ref[:doi]
      next unless cited_doi

      add_reference(all_references, cited_doi, cited_num, cited_ref, citing_doi, paper_info)
    end

    @recalculate = true
  end

  def add_reference(all_references, cited_doi, cited_num, cited_ref, citing_doi, paper_info)
    cited_info                        = cited_doi_info(cited_doi)

    # cited_info[:id]                 ||= id
    cited_info[:citations]            += 1
    cited_info[:info]                  =  cited_ref[:info] unless cited_info[:info]
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
      add_co_citation_counts(cited_num, groups, cited_info, all_references)
      add_section_summaries(groups, cited_info)

      add_citing_groups(groups, citing_info, paper_info)
    end

    cited_info.compact!
  end

  def cited_doi_info(doi)
    unless @results[:citations][ doi ]
      @results[:citations][ doi ] = {
        intra_paper_mentions: 0,
        citations:            0,
        citing_papers:        {},
        sections:             {},
        co_citation_counts:   {},
      }
      @results[:cited_count] += 1
    end

    @results[:citations][ doi ]
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
          citing_doi:    paper_info[:doi],
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

  def add_co_citation_counts(cited_num, groups, cited_info, all_references)
    co_citation_counts = cited_info[:co_citation_counts]

    groups.each do |group|

      # Aggregate co-citation counts
      group[:references].each do |co_citation_num|
        next if co_citation_num == cited_num

        cc_ref = all_references[co_citation_num] || all_references[co_citation_num.to_s.to_sym]
        co_citation_doi = cc_ref[:doi] || 'No-DOI'
        co_citation_counts[co_citation_doi] = co_citation_counts[co_citation_doi].to_i + 1
      end

    end
  end

  def recalculate_results(info)
  end

  def sort_results
    @results[:citations] = @results[:citations].sort.to_h
    @results[:citations].each do |doi, cited_info|
      cited_info[:citing_papers] = cited_info[:citing_papers].sort.to_h
    end

    # Don't sort these - matches are sorted by relevance
    # @results[:matches].sort!
  end

end