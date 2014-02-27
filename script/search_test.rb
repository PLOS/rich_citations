#!/usr/bin/env ./bin/rails runner

Rails.logger = Logger.new($stdout)

require 'pp'

SEARCH_SUBJECT = "circadian rhythms"
MAX_PAPERS = 5

pp Plos::PaperDatabase.analyze!(SEARCH_SUBJECT, MAX_PAPERS)

#
## Find information about a bunch of PLOS papers!
#puts "Searching..."
#results = Plos::Api.search(SEARCH_SUBJECT, query_type:"subject", rows:MAX_PAPERS)
#puts "Retrieving #{results.count}  papers from PLOS journals..."
#dois = results.map { |r| r['id'] }
#
#database = Plos::PaperDatabase.new
#
#dois.each do |doi|
#  puts "Fetching ... #{doi}"
#  xml = Plos::Api.document( doi )
#  #puts "Parsing ..."
#  parser = Plos::PaperParser.new(xml)
#  database.add_paper(doi, parser.references)
#end
#
#pp database.results
