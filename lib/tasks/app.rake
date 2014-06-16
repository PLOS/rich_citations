
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

end