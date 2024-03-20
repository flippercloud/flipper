require "connection_pool"
require "observer"

# Make ConnectionPool observable so we can reset the cache when the pool is reloaded or shutdown
ConnectionPool.class_eval do
  module ShutdownObservable
    def reload(&block)
      super(&block).tap do
        changed
        notify_observers
      end
    end

    def shutdown(&block)
      super(&block).tap do
        changed
        notify_observers
      end
    end
  end

  include Observable
  prepend ShutdownObservable
end

# An adapter that uses ConnectionPool to manage connections.
#
# Usage:
#
#   # Reuse an existing pool to create new adapters
#   pool = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
#   Flipper::Adapters::ConnectionPool.new(pool) do |client|
#     Flipper::Adapters::Redis.new(client)
#   end
#
#   # Create a new pool that returns the adapter
#   Flipper::Adapters::ConnectionPool.new(size: 5, timeout: 5) do
#     Flipper::Adapters::Redis.new(Redis.new)
#   end
class Flipper::Adapters::ConnectionPool
  include Flipper::Adapter

  # Use an existing ConnectionPool to initialize and cache new adapter instances.
  class Wrapper
    def initialize(pool, &initializer)
      @pool = pool
      @initializer = initializer
      @instances = {}

      # Reset the cache when the pool is reloaded or shutdown
      @pool.add_observer(self, :reset)
    end

    def with(&block)
      @pool.with do |resource|
        yield @instances[resource] ||= @initializer.call(resource)
      end
    end

    def reset
      @instances.clear
    end
  end

  attr_reader :pool

  def initialize(options = {}, &adapter_initializer)
    @pool = options.is_a?(ConnectionPool) ? Wrapper.new(options, &adapter_initializer) : ConnectionPool.new(options, &adapter_initializer)
  end

  OPERATIONS.each do |method|
    define_method(method) do |*args|
      @pool.with { |adapter| adapter.public_send(method, *args) }
    end
  end
end
