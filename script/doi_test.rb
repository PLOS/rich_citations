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

Rails.configuration.app.use_cached_info = false

require 'pp'

DOI='10.1371/journal.pone.0046843'
# DOI='10.1371/journal.pbio.0050222xxx'
# DOI='10.1371/journal.pone.0032408' # The Paper from Hell
# DOI='10.1371/journal.pbio.0050093' # DOI with odd hyphens
# DOI='10.1371/journal.pone.0041419' # ISBN
# DOI='10.1371/journal.pgen.1001139' # Pubmed ID
# DOI='10.1371/journal.pgen.1002666' # PMC ID
# DOI='10.1371/journal.pone.0036540' #  Arxiv ID
# DOI='10.1371/journal.pone.0038649' # Github
# DOI='10.1371/journal.pone.0071952' # Github

doi = ARGV.last || DOI

start_time = Time.now
puts "Starting at ----------------- #{start_time}"

xml = r = Plos::Api.document( doi )
# r = xml.css('ref-list')
# r = xml.css('body')
# puts r.to_xml; exit

info = PaperParser.parse_xml(xml)

if info
  pp info[:bibliographic]
else
  puts "\n*************** Document #{doi} could not be retrieved\n"
end

end_time = Time.now
puts "Finished at ----------------- #{end_time} == #{end_time - start_time}"
