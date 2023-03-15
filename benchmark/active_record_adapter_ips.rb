require 'bundler/setup'
require_relative './active_record_setup'
require 'flipper'
require 'flipper/adapters/active_record'
require 'benchmark/ips'

flipper = Flipper.new(Flipper::Adapters::ActiveRecord.new)

2000.times do |i|
  flipper.enable_actor :foo, Flipper::Actor.new("User;#{i}")
end

Benchmark.ips do |x|
  x.report("get_all") { flipper.preload_all }
end
