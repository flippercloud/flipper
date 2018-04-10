# Usage (from the repo root):
#   env TOKEN=<token> bundle exec ruby examples/cloud/basic.rb
require 'pathname'
require 'logger'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper'
require 'flipper/adapters/memory'
require 'flipper/cloud'

memory_adapter = Flipper::Adapters::Memory.new
memory_flipper = Flipper.new(memory_adapter)

memory_flipper.enable(:test)
memory_flipper.enable(:search)
memory_flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
memory_flipper.enable_percentage_of_time(:logging, 5)

flipper = Flipper::Cloud.new(ENV.fetch('TOKEN'))

# wipes cloud clean and makes it identical to memory flipper
flipper.import(memory_flipper)
