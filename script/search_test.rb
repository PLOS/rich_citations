#!/usr/bin/env ./bin/rails runner

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

Rails.logger = Logger.new($stdout)

require 'pp'

SEARCH_SUBJECT = "circadian rhythms"
MAX_PAPERS = 5

info =  PaperDatabase.analyze!(SEARCH_SUBJECT, MAX_PAPERS)
pp info

#
## Find information about a bunch of PLOS papers!
#puts "Searching..."
#results = Plos::Api.search(SEARCH_SUBJECT, query_type:"subject", rows:MAX_PAPERS)
#puts "Retrieving #{results.count}  papers from PLOS journals..."
#dois = results.map { |r| r['id'] }
#
#database = PaperDatabase.new
#
#dois.each do |doi|
#  puts "Fetching ... #{doi}"
#  xml = Plos::Api.document( doi )
#  #puts "Parsing ..."
#  parser = PaperParser.new(xml)
#  database.add_paper(doi, parser.paper_info)
#end
#
#pp database.results
