require File.expand_path('../example_setup', __FILE__)

require 'flipper'
require 'flipper/adapters/v2/memory'

# pick an adapter
adapter = Flipper::Adapters::V2::Memory.new

# get a handy dsl instance
flipper = Flipper.new(adapter)

# grab a feature
search = flipper[:search]

perform = lambda do
  # check if that feature is enabled
  if search.enabled?
    puts 'Search away!'
  else
    puts 'No search for you!'
  end
end

perform.call
puts 'Enabling Search...'
search.enable
perform.call
