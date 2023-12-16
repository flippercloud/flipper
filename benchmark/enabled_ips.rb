require 'bundler/setup'
require 'flipper'
require 'benchmark/ips'

actor = Flipper::Actor.new("User;1")

Benchmark.ips do |x|
  x.report("with actor") { Flipper.enabled?(:foo, actor) }
  x.report("without actor") { Flipper.enabled?(:foo) }
end
