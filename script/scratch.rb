#!/usr/bin/env ./bin/rails runner

# Search for papers containing reference text

require 'pp'

result = Plos::Api.search('pubmed', query_type:'reference', rows:5)
dois = result.map { |r| r['id'] }
pp dois
