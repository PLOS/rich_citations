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
      cited_authors = cited_info[:author]
      return if cited_authors.blank?

      self_citations = cited_authors.product(paper_authors).map do |cited, citing|
        reason = is_self_citation?(cited, citing)
        "#{cited[:given]} #{cited[:family]} [#{reason}]" if reason
      end.compact

      self_citations.presence
    end

    def is_self_citation?(cited, citing)
      return if cited[:affiliation] && citing[:affiliation] && cited[:affiliation] != citing[:affiliation]

      self_citation = []
      self_citation << "name"        if matches?( cited[:family] ,citing[:family],   cited[:given], citing[:given] )
      self_citation << "email"       if matches?( cited[:email], citing[:email]   )
      self_citation << "affiliation" if matches?( cited[:affiliation], citing[:affiliation] )

      self_citation.present? ? self_citation.join(',') : nil
    end

    def matches?(a1,a2, b1=nil,b2=nil)
      return false unless a1 && a2
      return false if a1.downcase != a2.downcase

      return true  unless b1 && b2
      return false if b1.downcase != b2.downcase

      return true
    end

    def paper_authors
      @paper_authors ||= result[:paper][:author]
    end

  end
end