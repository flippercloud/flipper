require 'bundler/setup'
require 'flipper'
require 'active_support/notifications'
require 'active_support/isolated_execution_state'
require 'benchmark/ips'

class FlipperSubscriber
  def call(name, start, finish, id, payload)
  end

  ActiveSupport::Notifications.subscribe(/flipper/, new)
end

actor = Flipper::Actor.new("User;1")
bare = Flipper.new(Flipper::Adapters::Memory.new)
instrumented = Flipper.new(Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

Benchmark.ips do |x|
  x.report("with instrumentation") { instrumented.enabled?(:foo, actor) }
  x.report("without instrumentation") { bare.enabled?(:foo, actor) }
end
