require 'pp'
require 'pathname'

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper'
require 'adapter/memory'

adapter = Adapter[:memory].new({})
search = Flipper::Feature.new(:search, adapter)

if search.enabled?
  puts 'Search away!'
else
  puts 'No search for you!'
end

puts 'Enabling Search...'
search.enable

if search.enabled?
  puts 'Search away!'
else
  puts 'No search for you!'
end
