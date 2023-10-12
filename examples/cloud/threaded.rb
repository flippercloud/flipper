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

# Check every second to see if the feature is enabled
5.times.map { |i|
  Thread.new {
    loop do
      sleep rand

      if Flipper[:stats].enabled?
        puts "#{Time.now.to_i} Enabled!"
      else
        puts "#{Time.now.to_i} Disabled!"
      end
    end
  }
}.each(&:join)
