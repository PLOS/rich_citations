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
    puts "Reprocessing up to #{max || 'all'} results older than #{days} days."
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
end
