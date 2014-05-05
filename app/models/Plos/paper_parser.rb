module Plos
  class PaperParser

    def self.is_failure?(paper_info)
      paper_info.blank? || paper_info[:failed]
    end

    attr_reader :doi, :xml

    def initialize(xml)
      @xml = xml
      @doi = xml.at('article-id[pub-id-type=doi]').content.strip if xml
    end

    # A citation group is all of the papers that are cited together at a certain point in the paper
    # -- the bare stuff of inline co-citations.
    # So, for example, a citation group might simply be [1], or it could be [2]-[10], or even
    # [11], [13]-[17], [21].
    # Returns an array of arrays containing reference numbers
    def citation_groups
      @citation_groups ||= begin

        grouper = Plos::CitationGrouper.new(self)

        citation_nodes.each do |citation|
          grouper.add_citation(citation)
        end

        grouper.groups
      end
    end

    def paper_info
      return {failed:true} unless xml

      {
          doi: doi,
          paper: {
              word_count: word_count,
          },
          references: references,
          groups:     citation_groups,
          authors:    authors,
      }
    end

    # Get all the references
    def references
      unless @references
        @references = {}
        @references_by_id = {}

        reference_nodes.each do |index, ref|
          reference   = { id: ref[:id] }

          info = info_for_reference[index]
          reference[:doi]  = info && info[:doi]
          reference[:info] = info
          reference[:self_citations] = self_citations(info)

          @references[index] = reference.compact
          @references_by_id[ref[:id]] = index
        end

        # Do these afterwards because they have a dependency
        add_citation_counts
        add_citation_sections
        add_median_co_citations
      end

      @references
    end

    def info_for_reference
      @info_for_reference ||= Plos::InfoResolver.resolve(reference_nodes)
    end

    # Get a list of references by ref id /rid
    def references_by_id
      references unless @references_by_id
      @references_by_id
    end

    # Find the reference number for an XREF node
    def reference_number(xref_node)
      refid = xref_node['rid']
      references_by_id[ refid ] || warn("There was an error getting the reference for #{refid}") || 0
    end

    def zero_mentions
      references.select { |num,info| info.zero_mentions }
    end

    # Get the outermost section title
    def section_title_for(node)
      title = nil

      while node && defined?(node.parent)
        if node.name == 'sec'
          title_node = node.css('> title')
          title = title_node.text if title_node && title_node.text
        end

        node = node.parent
      end

      title || '[Unknown]'
    end

    def word_count
      @body =  xml.search('body').first

      count = 0
      @body.traverse do |n|
        count+= n.text.word_count if n.text?
      end
      count
    end

    def word_count_upto(node)
      @body =  xml.search('body').first

      count = 1
      @body.traverse do |n|
        return count if n==node
        count+= n.text.word_count if n.text?
      end

      nil
    end

    private

    # MICC = median in-line co-citations
    # @mro - aka micc_dictionary
    def add_median_co_citations
      all_groups = citation_groups

      references.each do |ref_num, info|
        cited_groups = all_groups.select { |g| g[:references].include?(ref_num) }

        median_co_citations = if cited_groups.present?
                                cocite_counts = cited_groups.map { |g| g.count - 1 }
                                cocite_counts.median
                              else
                                -1
                              end

        info[:citation_groups]     = cited_groups if cited_groups.present?
        info[:median_co_citations] = median_co_citations
        info[:zero_mentions]       = true if cited_groups.empty?
      end
    end

    def add_citation_sections
      citation_nodes.each do |citation|
        ref_num = reference_number(citation)
        title   = section_title_for(citation)

        info = references[ref_num]
        sections = info[:sections] ||= {}
        sections[title] = sections[title].to_i + 1
      end
    end

    # The number of times each reference is cited in the paper
    # @mro aka ipm_dictionary
    def add_citation_counts
      all_citations = citation_groups.map{|g| g[:references]}.flatten
      all_citations.group_by {|n| n }.each { |k,v| references[k][:mentions] = v.count }
    end

    def info_page_references
      @info_page_references ||= begin
        paper_html = Api.info(doi)
        references = paper_html.css('.references > li')
        references.map.with_index{ |r,i| [i,r] }.to_h
      end
    end

    def reference_nodes
      @reference_nodes ||= begin
          xml.css('ref-list ref').map.with_index{ |n,i| [i+1, n] }.to_h
      end
    end

    def citation_nodes
      @citation_nodes ||= xml.search('xref[ref-type=bibr]')
    end

    def affiliations
      unless @affiliations
        @affiliations = {}
        nodes = xml.css('article-meta aff')

        nodes.each do |node|
          text_node = node.css('addr-line')
          text_node = node if text_node.empty?
          @affiliations[ node['id']] = text_node.text
        end
      end

      @affiliations
    end

    def authors
      unless @authors
        @authors = []
        nodes = xml.css('article-meta contrib[contrib-type=author]')

        nodes.each do |node|
           @authors << {
               fullname:    author_fullname(node),
               email:       author_email(node),
               affiliation: author_affiliation(node),
           }.compact
        end
      end

      @authors
    end

    def author_fullname(node)
      (node.css('given-names').text.strip + ' ' + node.css('surname').text.strip).strip
    end

    def author_email(node)
      xref = node.css('xref[ref-type=corresp]')

      if xref.present?
        rid = xref.first['rid']
        corresp = xml.css("article-meta corresp##{rid}")
        email = corresp.css('email')

        if email.present?
          email.text
        elsif corresp.present?
          corresp.text
        end
      end
    end

    def author_affiliation(node)
      xref = node.css('xref[ref-type=aff]')

      if xref.present?
        rid = xref.first['rid']
        affiliations[rid]
      end
    end

    def self_citations(cited_info)
      cited_authors = cited_info[:authors]
      return if cited_authors.blank?

      result = cited_authors.product(authors).map do |cited, citing|
         reason = is_self_citation?(cited, citing)
         "#{cited[:fullname]} [#{reason}]" if reason
      end.compact

      result.present? ? result : nil
    end

    def is_self_citation?(cited, citing)
      return if cited[:affiliation] && citing[:affiliation] && cited[:affiliation] != citing[:affiliation]

      result = []
      result << "name"        if cited[:fullname]    && cited[:fullname]    == citing[:fullname]
      result << "email"       if cited[:email]       && cited[:email]       == citing[:email]
      result << "affiliation" if cited[:affiliation] && cited[:affiliation] == citing[:affiliation]

      result.present? ? result.join(',') : nil
    end

  end # class
end