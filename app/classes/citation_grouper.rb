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
    start_group!(citation) if citation.previous_sibling != @last_node

    @last_node = citation
    number = parser.number_for_citation_node(citation)

    if @hyphen_found
      add_node(citation)
      add_range(number)
    else
      add_node(citation)
      add(number)
      @last_number = number
    end

    parse_text_separators(citation)
  end

  private

  def add(number)
    id = parser.reference_id_for_number(number)
    @current_group[:references].push(id)
  end

  def add_range(range_end)
    range_start = @last_number + 1
    (range_start..range_end).each { |number| add(number) }
  end

  def add_node(node)
    @current_group[:nodes].push node
  end

  def start_group!(node)
    @current_group =  {
        references:    [],
        nodes:         [],
    }

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
