
# Load everything in lib/extensions

Dir[Rails.root.join("lib/extensions/**/*.rb")].each {|f| require f}

