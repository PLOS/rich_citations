# coding: utf-8
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

module Id
  class Doi < Base

    # DOI parsing is painful since, in theory, a DOI can contain any character
    # The following assumptions are made:
    #   A DOI cannot contain (unencoded) whitespace or quotes (Since they might be in an attribute)
    #   A DOI cannot end with punctuation (so that we can separate a DOI from following punctuation)

    DOI_PREFIX_CHAR  = %q{[^\/[[:space:]]]}
    DOI_CHAR         = %q{[^[[:space:]]'"]}
    DOI_END_CHAR     = NPUNCT
    DOI_REGEX        = "10\\.#{DOI_PREFIX_CHAR}+(\\/|%2[Ff])#{DOI_CHAR}*#{DOI_END_CHAR}+"

    DOI_PREFIX_REGEX = /\bdoi:?\s*(?<result>#{DOI_REGEX})/io
    DOI_URL_REGEX    = /\bdoi\.org\/(?<result>#{DOI_REGEX})/io
    DOI_ALONE_REGEX  = /^(#{PUNCT}|\s)*(?<result>#{DOI_REGEX})/io

    PLOS_PREFIXES = [ '10.1371' ]
    ELIFE_PREFIXES = [ '10.7554' ]
    PEERJ_PREFIXES = [ '10.7717' ]
    
    def self.extract(text, normalize=false)
      doi = match_regexes(text, DOI_URL_REGEX    => true,
                                DOI_PREFIX_REGEX => false,
                                DOI_ALONE_REGEX  => false  )

      doi = cleanup(doi)
      normalize ? normalize(doi) : doi
    end

    def self.extract_list(text)
      list = (text || '').split(/(",|',|`,|\s)\s*/)
      list.map!{|i| extract(i) }
      list.select(&:present?)
    end

    def self.normalize(doi)
      doi.present? ? doi.strip.tr('–','-') : nil
    end

    def self.prefix(doi)
      doi && doi.strip.split('/',2).first
    end

    def self.is_plos_doi?(doi)
      prefix(doi).in?(PLOS_PREFIXES)
    end

    def self.is_elife_doi?(doi)
      prefix(doi).in?(ELIFE_PREFIXES)
    end

    def self.is_peerj_doi?(doi)
      prefix(doi).in?(PEERJ_PREFIXES)
    end

    private

    # Some stuff which is just too tricky to handle with regexes
    def self.cleanup(doi)
      # Handle DOIs that have an ending XML delimiter in them
      if doi =~ /<\//
        doi = doi.sub(/<\/.*/,'')
        doi = doi.sub(/#{PUNCT}+$/o,'')
      end

      doi
    end

  end
end
