require 'bundler/setup'
require_relative './active_record_setup'
require 'flipper'
require 'flipper/adapters/active_record'
require 'benchmark/ips'

flipper = Flipper.new(Flipper::Adapters::ActiveRecord.new)

10.times do |n|
  2000.times do |i|
    flipper.enable_actor 'feature' + n.to_s, Flipper::Actor.new("User;#{i}")
  end
end

Benchmark.ips do |x|
  x.report("get_all") { flipper.preload_all }
  x.report("features") { flipper.features }
end
