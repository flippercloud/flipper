# Usage (from the repo root):
#   env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/import.rb
require 'bundler/setup'
require 'flipper'
require 'flipper/cloud'

Flipper.enable(:test)
Flipper.enable(:search)
Flipper.enable_actor(:stats, Flipper::Actor.new("jnunemaker"))
Flipper.enable_percentage_of_time(:logging, 5)

cloud = Flipper::Cloud.new

# makes cloud identical to memory flipper
cloud.import(Flipper)
