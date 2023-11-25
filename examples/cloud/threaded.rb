# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/threaded.rb

require_relative "./cloud_setup"
require 'bundler/setup'
require 'flipper/cloud'

puts Process.pid

Flipper.configure do |config|
  config.default {
    Flipper::Cloud.new(
      local_adapter: config.adapter,
      debug_output: STDOUT,
    )
  }
end

# You might want to do this at some point to see different results:
# Flipper.enable(:search)
# Flipper.disable(:stats)

# Check every second to see if the feature is enabled
5.times.map { |i|
  Thread.new {
    loop do
      sleep rand

      Flipper.enabled?(:stats)
      Flipper.enabled?(:search)
    end
  }
}.each(&:join)
