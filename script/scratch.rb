#!/usr/bin/env ./bin/rails runner

# Search for papers containing reference text

require 'pp'

result = Plos::Api.search('pmcid', query_type:'reference', rows:100)
result.each do |r|
  doi = r['id']
  pp "-- DOI #{doi}"
  info= PaperParser.parse_doi(doi)
end
