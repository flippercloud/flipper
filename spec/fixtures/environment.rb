# Placeholder for config/environment.rb

unless ENV["FLIPPER_REQUIRE"]
  require 'flipper'
  require 'flipper/adapters/pstore'

  Flipper.configure do |config|
    config.adapter { Flipper::Adapters::PStore.new }
  end
end
