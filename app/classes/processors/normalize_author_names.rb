module Processors
  class NormalizeAuthorNames < Base
    include Helpers

    def process
      paper_authors.each     do |author| normalize_author_name(author) end
      reference_authors.each do |author| normalize_author_name(author) end
    end

    def self.dependencies
      [Authors, ReferencesInfoFromCitationNode, ReferencesInfoFromCitationText]
    end

    protected

    def normalize_author_name(author)
      return unless author
      given, family, literal = author.values_at(:given, :family, :literal)
      author[:given]   = given.titleize   if all_caps(family) && all_caps(given)&& should_titleize_given(given)
      author[:family]  = family.titleize  if all_caps(family) && all_caps(given)
      author[:literal] = literal.titleize if all_caps(literal)
    end

    def all_caps(string)
      string.present? && string == string.upcase
    end

    def should_titleize_given(given)
      # Rough attempt to only titleize strings that don't look like initials JA Smith or J.A.Smith
      given.length>2 && given =~ /\w{2}/
    end

    def reference_authors
      @reference_authors ||= references.map do |id, ref| ref[:info][:authors] end.flatten
    end

    def paper_authors
      @paper_authors ||= result[:paper].try(:[], :authors)
    end

  end
end