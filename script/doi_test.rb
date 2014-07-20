#!/usr/bin/env ./bin/rails runner

Rails.logger = Logger.new($stdout)

Rails.configuration.app.use_cached_info = false

require 'pp'

DOI='10.1371/journal.pone.0046843'
DOI='10.1371/journal.pbio.0050222xxx'
DOI='10.1371/journal.pone.0032408' # The Paper from Hell
DOI='10.1371/journal.pbio.1001675'
DOI='10.1371/journal.pone.0047692'
DOI='10.1371/journal.pone.0098172'
DOI='10.1371/journal.pbio.1001675'
DOI='10.1371/journal.pbio.0050093' # DOI with odd hyphens
DOI='10.1371/journal.pone.0041419' # ISBN
DOI='10.1371/journal.pone.0097128'
DOI='10.1371/journal.pone.0067380'
DOI='10.1371/journal.pone.0097165'
DOI='10.1371/journal.pone.0041419'
DOI='10.1371/journal.pgen.1001139' # Pubmed ID
DOI='10.1371/journal.pgen.1002666' # PMC ID
# DOI='10.1371/journal.pone.0038649' # Github
# DOI='10.1371/journal.pone.0071952' # Github

start_time = Time.now
puts "Starting at ----------------- #{start_time}"

xml = r = Plos::Api.document( DOI )
# r = xml.css('ref-list')
# r = xml.css('body')
# puts r.to_xml; exit

info = PaperParser.parse_xml(xml)

if info
  pp info
else
  puts "\n*************** Document #{DOI} could not be retrieved\n"
end

end_time = Time.now
puts "Finished at ----------------- #{end_time} == #{end_time - start_time}"
