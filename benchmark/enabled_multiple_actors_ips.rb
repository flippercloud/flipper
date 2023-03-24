require 'bundler/setup'
require 'flipper'
require 'benchmark/ips'

actor1 = Flipper::Actor.new("User;1")
actor2 = Flipper::Actor.new("User;2")
actor3 = Flipper::Actor.new("User;3")
actor4 = Flipper::Actor.new("User;4")
actor5 = Flipper::Actor.new("User;5")
actor6 = Flipper::Actor.new("User;6")
actor7 = Flipper::Actor.new("User;7")
actor8 = Flipper::Actor.new("User;8")

actors = [actor1, actor2, actor3, actor4, actor5, actor6, actor7, actor8]

Benchmark.ips do |x|
  x.report("with array of actors") { Flipper.enabled?(:foo, actors) }
  x.report("with multiple enabled? checks") { actors.each { |actor| Flipper.enabled?(:foo, actor) } }
  x.compare!
end
