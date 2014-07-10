module Processors
  class SelfCitations < Base
    include Helpers

    def process
      references.each do |id, ref|
        ref[:self_citations] = self_citations_for( ref[:info] )
      end
    end

    def self.dependencies
      NormalizeAuthorNames
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
      self_citation << "name"        if name_matches?( cited, citing )
      self_citation << "email"       if matches?( cited[:email], citing[:email]   )
      self_citation << "affiliation" if matches?( cited[:affiliation], citing[:affiliation] )

      self_citation.present? ? self_citation.uniq.join(',') : nil
    end

    def matches?(a1,a2, b1=nil,b2=nil)
      return false unless a1.present? && a2.present?
      return false if a1.casecmp(a2) != 0

      return true  unless b1.present? && b2.present?
      return false if b1.casecmp(b2) != 0

      return true
    end

    def name_matches?(a, b)
      a_alternatives = name_alternatives(a)
      b_alternatives = name_alternatives(b)

      a_alternatives.product(b_alternatives).each do |a,b|
        return true if a.casecmp(b)==0
      end

      false
    end

    def name_alternatives(author)
      result = []

      if author[:literal]
        result << author[:literal]
        family, given = author[:literal].split(/,\s*/,2)
        result << "#{given} #{family}" if given.present?
      end

      if author[:given].present? && author[:family].present?
        result << "#{author[:family]}, #{author[:given]}"
        result << "#{author[:given]} #{author[:family]}"
      end

      result.map { |r| normalize_name(r) }
    end

    def normalize_name(name)
      # Squash initals for comparison
      name.gsub(/\.\s*/,'').strip
    end

    def paper_authors
      @paper_authors ||= result[:paper][:author]
    end

  end
end