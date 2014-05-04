#!/usr/bin/env ./bin/rails runner

Rails.logger = Logger.new($stdout)

require 'pp'

DOI='10.1371/journal.pone.0046843'
DOI='10.1371/journal.pbio.0050222xxx'
DOI='10.1371/journal.pone.0032408' # The Paper from Hell
DOI='10.1371/journal.pbio.1001675'

xml = Plos::Api.document( DOI )
# r = xml.css('ref-list')
# puts xml.to_xml; exit

parser = Plos::PaperParser.new(xml)
info = parser.paper_info

if info
  pp info
else
  puts "\n*************** Document #{DOI} could not be retrieved\n"
end
