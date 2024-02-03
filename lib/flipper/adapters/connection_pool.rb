# An adapter that uses ConnectionPool to manage connections.
#
# Usage:
#
#   pool = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
#   Flipper::Adapters::ConnectionPool.new(pool) do |client|
#     Flipper::Adapters::Redis.new(client)
#   end
#
class Flipper::Adapters::ConnectionPool
  include Flipper::Adapter

  def initialize(pool = nil, &adapter_initializer)
    @pool = pool
    @adapter_initializer = adapter_initializer
  end

  OPERATIONS.each do |method|
    define_method(method) do |*args|
      @pool.with do |connection|
        @adapter_initializer.call(connection).public_send(method, *args)
      end
    end
  end
end
