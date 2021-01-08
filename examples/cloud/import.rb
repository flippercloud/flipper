# Usage (from the repo root):
#   env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/import.rb
require 'pathname'
require 'logger'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper'
require 'flipper/cloud'

memory_adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(memory_adapter)

flipper.enable(:test)
flipper.enable(:search)
flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
flipper.enable_percentage_of_time(:logging, 5)

cloud = Flipper::Cloud.new

# makes cloud identical to memory flipper
cloud.import(flipper)
