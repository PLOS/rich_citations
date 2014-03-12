
namespace :scheduler do

  desc "Remove old Results and Papers. This task is called by the Heroku scheduler add-on"
  task :remove_old_searches => :environment do
    puts "Removing old records..."
    RemoveOldSearches.run!
    puts "done."
  end

end
