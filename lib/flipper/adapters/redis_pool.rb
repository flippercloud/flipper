require 'flipper/adapters/redis'
require 'connection_pool'

module Flipper
  module Adapters
    class RedisPool < Redis
      def initialize(pool, key_prefix: nil)
        @pool = pool
        @key_prefix = key_prefix
      end

      superclass.instance_methods(false).each do |method|
        define_method method do |*args|
          return super(*args) unless @client.nil?

          @pool.with do |client|
            @client = client
            super(*args).tap { @client = nil }
          end
        end
      end
    end
  end
end


Flipper.configure do |config|
  config.adapter do
    client = ConnectionPool.new(size: 1) { Redis.new(url: ENV["FLIPPER_REDIS_URL"] || ENV["REDIS_URL"]) }
    Flipper::Adapters::RedisPool.new(client)
  end
end
