#!/usr/bin/env ruby

require 'pp'

require_relative 'extensions'
require_relative 'plos/api'
require_relative 'plos/paper_database'
require_relative 'plos/paper_parser'

SEARCH_SUBJECT = "circadian rhythms"
MAX_PAPERS = 500

# Find information about a bunch of PLOS papers!
puts "Searching..."
results = Plos::API.search(SEARCH_SUBJECT, query_type:"subject", rows:MAX_PAPERS)
puts "Retrieving #{results.count}  papers from PLOS journals..."
dois = results.map { |r| r['id'] }

database = Plos::PaperDatabase.new

dois.each do |doi|
  puts "Fetching ... #{doi}"
  xml = Plos::API.document( doi )
  #puts "Parsing ..."
  parser = Plos::PaperParser.new(xml)
  database.add_paper(doi, parser.references)
end

pp database.results
