Sidekiq.configure_server do |config|
  database_url = ENV['DATABASE_URL']
  if database_url
    ENV['DATABASE_URL'] = "#{database_url}?pool=20"
    ActiveRecord::Base.establish_connection
  end
end

Sidekiq.configure_client do |config|
  # 5 redis connections should be more than enough
  config.redis = { size: 5 }
end  
