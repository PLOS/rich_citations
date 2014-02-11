require 'active_support/core_ext/object/blank'

module Plos
  class PaperParser

    attr_reader :doi, :paper, :xml

    def initialize(paper, xml)
      @paper = paper
      @xml   = xml

      @citation_numbers = {}
    end

    def parse
      @doi = xml.at('article-id[pub-id-type=doi]').content
      paper.doi = @doi

      ref = references
      ipms = citation_counts
      miccs = median_co_citations

      references.each do |num, ref|
        if ref[:doi]
          paper.intra_paper_mentions << ipms[num]
          paper.median_co_citations  << miccs[num]
        end
      end

      paper.zero_mentions = zero_mentions

      paper
    end

    # Returns citation reference numbers in the paper's list of references that are not actually mentioned in the text of the paper.
    # (This is against PLOS editorial policy, but it happens.)
    # Returns a list of all such entries or nil
    def zero_mentions
      mentions = citation_counts.map { |num, count| count == 0 ? num : nil }.compact
      mentions.presence
    end

    # MICC = median in-line co-citations
    # @mro - aka micc_dictionary
    def median_co_citations
      unless @micc_dictionary
        @micc_dictionary = {}
        all_groups = citation_groups

        (1..references.count).each do |ref_num|
          cited_groups = all_groups.select { |g| g.include?(ref_num) }

          @micc_dictionary[ref_num] = if cited_groups.present?
            cocite_counts = cited_groups.map { |g| g.count - 1 }
            cocite_counts.median
          else
            -1
          end
        end

      end

      @micc_dictionary
    end

    # The number of times each reference is cited in the paper
    # @mro aka ipm_dictionary
    def citation_counts
      @citation_counts ||= citation_groups.flatten.group_by {|n| n }.map { |k,v| [k, v.count] }.to_h
    end

    # A citation group is all of the papers that are cited together at a certain point in the paper
    # -- the bare stuff of inline co-citations.
    # So, for example, a citation group might simply be [1], or it could be [2]-[10], or even
    # [11], [13]-[17], [21].
    # Returns an array of arrays containing reference numbers
    def citation_groups
      @citation_groups ||= begin

        grouper = CitationGrouper.new(self)

        xml.search('xref[ref-type=bibr]').each do |citation|
          grouper.add_citation(citation)
        end

        grouper.groups

      end
    end

    # Find the reference number for an XREF node
    def reference_number(xref_node)
      refid = xref_node['rid']
      references_by_id[ refid ] || warn("There was an error getting the reference for #{refid}") || 0
    end

    # Get all the references
    def references
      unless @references
        @references = {}
        @references_by_id = {}
        xml.css('ref').each_with_index do |ref, i|
          index = i + 1
          @references[index] = {
              id:   ref[:id],
              doi:  doi_for_reference(ref, info_page_references[index])
          }
          @references_by_id[ref[:id]] = index
        end
      end

      @references
    end

    # Get a list of references by ref id /rid
    def references_by_id
      references unless @references_by_id
      @references_by_id
    end

    private

    def extract_doi(text)
      match = text.match( /\sdoi:|\.doi\./i)
      return nil unless match

      # all DOI's start with 10., see reference here: http://www.doi.org/doi_handbook/2_Numbering.html#2.2
      match = text.match( /(\s)*(10\.)/, match.end(0) )
      return nil unless match

      match = text.match( /[\w\.\/]*/, match.begin(2))
      result = match[0]
      result = result[0..-2] if result.end_with?('.')
      result
    end

    def doi_for_reference(ref, info_page_ref )
      # Note: Removed code that used cross-refs

      # inline DOI or DOI from Web Page references list
      extract_doi(ref.text) || extract_doi( info_page_ref.inspect )
    end

    def info_page_references
      @info_page_references ||= begin
        paper_html = API.info(doi)
        references = paper_html.css('[class=references] > li')
        references.map.with_index{ |r,i| [i,r] }.to_h
      end
    end

    # class to help in grouping citations
    class CitationGrouper

      HYPHEN_SEPARATORS = ["-", "\u2013", "\u2014"]
      ALL_SEPARATORS    = [',', ''] + HYPHEN_SEPARATORS

      attr_reader :parser,
                  :groups

      def initialize(parser)
        @parser    = parser
        @last_node = :none
        @groups    = []
      end

      def add_citation(citation)
        start_group! if citation.previous_sibling != @last_node

        @last_node = citation
        number = parser.reference_number(citation)

        if @hyphen_found
          add_range(number)
        else
          add(number)
        end

        parse_text_separators(citation)
      end

      private

      def add(number)
        @current_group.push number
      end

      def add_range(range_end)
        range_start = @current_group.last+1
        (range_start..range_end).each { |n| add n }
      end

      def start_group!
        @current_group =  []
        @groups        << @current_group
        @last_node     =  :none
      end

      def parse_text_separators(citation)
        @hyphen_found = false
        sibling = citation.next_sibling

        while is_separator?(sibling) do
          @last_node = sibling
          @hyphen_found ||= HYPHEN_SEPARATORS.include?(sibling.text.strip)
          sibling = sibling.next_sibling
        end
      end

      def is_separator?(node)
        return false unless node && node.text?
        return ALL_SEPARATORS.include?(node.text.strip)
      end

    end

  end # class
end