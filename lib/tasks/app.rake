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
require 'sidekiq/api'

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

  namespace :process do
    desc 'Reprocess papers over [days=30] old'
    task old: :environment do
      days = (ENV['days'] || 30).to_i
      max  = ENV['max'].present? && ENV['max'].to_i
      q = PaperResult.where('updated_at < ?', days.days.ago)
      total_count = q.count
      q = q.limit(max)
      count = q.count
      puts "Reprocessing #{count} (of #{total_count}) results older than #{days} days."
      args = PaperResult.where('updated_at < ?', days.days.ago).limit(max)
             .select(:doi).map(&:doi).map do |doi|
        puts doi
        [doi, days]
      end
      Sidekiq::Client.push_bulk('class' => ReprocessPaper, 'args' => args)
    end

    desc 'Process recent DOIs from PLOS; use days=10 to specify to process the last 10 days'
    task recent: :environment do
      client = HTTPClient.new
      days = (ENV['days'] || 30).to_i
      params = { 'q' => "publication_date:[NOW-#{days}DAY/DAY TO NOW-1DAY/DAY]",
                 'fl' => 'id,publication_date',
                 'fq' => 'doc_type:full',
                 'article_type' => 'Research Article',
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

    desc 'Clear job queue.'
    task clear: :environment do
      Sidekiq::Queue.new.clear
    end
  end
end
