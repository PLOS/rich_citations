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

require 'httpclient'

namespace :app do

  namespace :scheduler do
    desc "Remove old Results and Papers. This task is called by the Heroku scheduler add-on"
    task :remove_old_searches => :environment do
      puts "Removing old records..."
      RemoveOldSearches.run!
      puts "done."
    end
  end

  desc "Purge all Results and Papers."
  task :purge => :environment do
    puts "Removing records..."
    RemoveOldSearches.run_all!
    puts "done."
  end

  task :dump_dois => :environment do
    $stdout.write('["')
    $stdout.write(PaperResult.pluck(:doi).join("\",\n\""))
    $stdout.write('"]')
  end

  desc 'Reprocess papers over 30 days old.'
  task reprocess: :environment do
    days = (ENV['days'] || 30).to_i
    max  = ENV['max'].present? && ENV['max'].to_i
    q = PaperResult.where('updated_at < ?', days.days.ago)
    total_count = q.count
    q = q.limit(max)
    count = q.count
    puts "Reprocessing #{count} (of #{total_count}) results older than #{days} days."
    PaperResult.where('updated_at < ?', days.days.ago).limit(max).each do |p|
      doi = p.doi
      puts doi
      p.destroy!
      AnalyzePaper.perform_async(doi)
    end
  end

  desc 'Process DOIs from stdin list.'
  task process: :environment do
    $stdin.each_line do |doi|
      doi = doi.chomp
      paper = PaperResult.find_by(doi: doi)
      paper.destroy! if paper
      puts doi
      AnalyzePaper.perform_async(doi)
    end
  end

  desc 'Process recent DOIs from PLOS; use days=10 to specify to process the last 10 days'
  task process_recent: :environment do
    client = HTTPClient.new
    days = (ENV['days'] || 30).to_i
    params = { 'q' => "publication_date:[NOW-#{days}DAY/DAY TO NOW]",
               'fl' => 'id,publication_date',
               'fq' => 'doc_type:full',
               'wt' => 'json',
               'rows' => 10_000 }
    resp = client.get('http://api.plos.org/search', params)
    dois = MultiJson.load(resp.body)['response']['docs'].map { |x| x['id'] }
    dois.each do |doi|
      next if PaperResult.exists?(doi: doi)
      puts doi
      AnalyzePaper.perform_async(doi)
    end
  end
end
