module Processors
  class SelfCitations < Base

    def process
      result[:references].each do |id, ref|
        ref[:self_citations] = self_citations_for( ref[:info] )
      end
    end

    def self.dependencies
      [Authors, ReferencesInfoFromCitationNode, ReferencesInfoFromCitationText]
    end

    protected

    def self_citations_for(cited_info)
      cited_authors = cited_info[:author]
      return if cited_authors.blank?

      self_citations = cited_authors.product(paper_authors).map do |cited, citing|
        reason = is_self_citation?(cited, citing)
        if reason
          name = citing[:literal] || "#{citing[:family]}, #{citing[:given]}"
          "#{name} [#{reason}]" if reason
        end
      end.compact

      self_citations.presence
    end

    def is_self_citation?(cited, citing)
      return if cited[:affiliation] && citing[:affiliation] && cited[:affiliation] != citing[:affiliation]

      self_citation = []
      self_citation << "name"        if matches?( cited[:family] ,citing[:family],   cited[:given], citing[:given] )
      self_citation << "name"        if matches?( cited[:literal],citing[:literal] )
      self_citation << "name"        if matches?( "#{cited[:family] }, #{cited[:given] }",   citing[:literal] )
      self_citation << "name"        if matches?( "#{citing[:family]}, #{citing[:given]}",   cited[:literal]  )
      self_citation << "email"       if matches?( cited[:email], citing[:email]   )
      self_citation << "affiliation" if matches?( cited[:affiliation], citing[:affiliation] )

      self_citation.present? ? self_citation.uniq.join(',') : nil
    end

    def matches?(a1,a2, b1=nil,b2=nil)
      return false unless a1.present? && a2.present?
      return false if a1.downcase != a2.downcase

      return true  unless b1.present? && b2.present?
      return false if b1.downcase != b2.downcase

      return true
    end

    def paper_authors
      @paper_authors ||= result[:paper][:author]
    end

  end
end