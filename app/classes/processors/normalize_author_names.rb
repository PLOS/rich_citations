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
      @reference_authors ||= references.map do |id, ref| ref[:info][:author] end.flatten
    end

    def paper_authors
      @paper_authors ||= result[:paper].try(:[], :author)
    end

  end
end
