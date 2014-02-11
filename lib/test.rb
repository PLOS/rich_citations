#!/usr/bin/env ruby

require 'pp'

require_relative './extensions'
require_relative './plos/api'
require_relative './plos/paper'
require_relative './plos/paper_parser'

SEARCH_SUBJECT = "circadian rhythms"
MAX_PAPERS = 500 #@mro

# Find information about a bunch of PLOS papers!
puts "Searching..."
results = Plos::API.search(SEARCH_SUBJECT, query_type:"subject", rows:MAX_PAPERS)
puts "Retrieving #{results.count}  papers from PLOS journals..."
## pp results[0]
dois = results.map { |r| r['id'] }
## puts dois

#doi = "10.1371/journal.pcbi.1000712"
#doi = "10.1371/journal.pgen.1003361"
#begin
dois.each do |doi|
puts "Fetching ... #{doi}"
xml = Plos::API.document( doi )
#puts "Parsing ..."
#puts xml
paper = Plos::Paper.new
parser = Plos::PaperParser.new(paper, xml)
parser.parse
#parser.citation_groups
#  pp parser.references
#  pp parser.median_co_citations
#  pp paper
end

#pp paper

#gg = parser.citation_groups
# pp gg

# pp parser.citation_groups
# pp parser.median_co_citations

