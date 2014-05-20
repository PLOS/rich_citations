module Processors
  class SelfCitations < Base

    def process
      result[:references].each do |id, ref|
        ref[:self_citations] = self_citations_for( ref[:info] )
      end
    end

    def self.dependencies
      [Authors, ReferencesInfo]
    end

    protected

    def self_citations_for(cited_info)
      cited_authors = cited_info[:authors]
      return if cited_authors.blank?

      self_citations = cited_authors.product(paper_authors).map do |cited, citing|
        reason = is_self_citation?(cited, citing)
        "#{cited[:fullname]} [#{reason}]" if reason
      end.compact

      self_citations.presence
    end

    def is_self_citation?(cited, citing)
      return if cited[:affiliation] && citing[:affiliation] && cited[:affiliation] != citing[:affiliation]

      self_citation = []
      self_citation << "name"        if cited[:fullname]    && cited[:fullname]    == citing[:fullname]
      self_citation << "email"       if cited[:email]       && cited[:email]       == citing[:email]
      self_citation << "affiliation" if cited[:affiliation] && cited[:affiliation] == citing[:affiliation]

      self_citation.present? ? self_citation.join(',') : nil
    end

    def paper_authors
      @paper_authors ||= result[:paper][:authors]
    end

  end
end