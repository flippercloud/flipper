# Just a simple example that shows how the backoff policy works.
require 'bundler/setup'
require 'flipper/cloud/telemetry/backoff_policy'

intervals = []
policy = Flipper::Cloud::Telemetry::BackoffPolicy.new

5.times do |n|
  intervals << policy.next_interval
end

pp intervals.map { |i| i.round(2) }
puts "Total: #{intervals.sum.round(2)}ms (#{(intervals.sum/1_000.0).round(2)} sec)"
