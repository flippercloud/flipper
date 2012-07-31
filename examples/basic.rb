require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
search = Flipper::Feature.new(:search, adapter)

perform = lambda do
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
