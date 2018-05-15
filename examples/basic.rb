require File.expand_path('../example_setup', __FILE__)

require 'flipper'

Flipper.configure do |config|
  config.default do
    # pick an adapter, this uses memory, any will do
    adapter = Flipper::Adapters::Memory.new

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end

# check if search is enabled
if Flipper.enabled?(:search)
  puts 'Search away!'
else
  puts 'No search for you!'
end

puts 'Enabling Search...'
Flipper.enable(:search)

# check if search is enabled
if Flipper.enabled?(:search)
  puts 'Search away!'
else
  puts 'No search for you!'
end
