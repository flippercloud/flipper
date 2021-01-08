# Usage (from the repo root):
#   env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/basic.rb
require 'pathname'
require 'logger'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper'
require 'flipper/cloud'

memory_adapter = Flipper::Adapters::Memory.new
existing_flipper = Flipper.new(memory_adapter)

existing_flipper.enable(:test)
existing_flipper.enable(:search)
existing_flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
existing_flipper.enable_percentage_of_time(:logging, 5)

# Don't provide a local adapter when doing an import from a local flipper
# instance. If you use the same local adapter as what you want to import from,
# you'll end up wiping out your local adapter.
cloud_flipper = Flipper::Cloud.new

pp memory_adapter.get_all
cloud_flipper.import(existing_flipper)
pp memory_adapter.get_all
