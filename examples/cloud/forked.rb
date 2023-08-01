# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/threaded.rb

require_relative "./cloud_setup"
require 'bundler/setup'
require 'flipper/cloud'

pids = 5.times.map do |n|
  fork {
    # Check every second to see if the feature is enabled
    threads = []
    5.times do
      threads << Thread.new do
        loop do
          sleep rand

          if Flipper[:stats].enabled?
            puts "#{Process.pid} #{Time.now.to_i} Enabled!"
          else
            puts "#{Process.pid} #{Time.now.to_i} Disabled!"
          end
        end
      end
    end
    threads.map(&:join)
  }
end

pids.each do |pid|
  Process.waitpid pid, 0
end
