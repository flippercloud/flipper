require File.expand_path('../example_setup', __FILE__)

require 'flipper'

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
