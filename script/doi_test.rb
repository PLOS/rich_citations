#!/usr/bin/env ./bin/rails runner

Rails.logger = Logger.new($stdout)

require 'pp'

DOI='10.1371/journal.pone.0046843'

xml = Plos::Api.document( DOI )
parser = Plos::PaperParser.new(xml)
info = parser.paper_info
pp info