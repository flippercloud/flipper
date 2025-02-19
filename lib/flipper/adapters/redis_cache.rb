require 'redis'
require 'flipper'
require 'flipper/adapters/cache_base'
require 'flipper/adapters/redis_shared/methods'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Redis.
    class RedisCache < CacheBase
      include ::Flipper::Adapters::RedisShared

      def initialize(adapter, cache, ttl = 3600, prefix: nil)
        @client = cache
        super
      end

      private

      def cache_fetch(key, &block)
        cached = with_connection { |conn| conn.get(key) }
        if cached
          Marshal.load(cached)
        else
          to_cache = yield
          cache_write key, to_cache
          to_cache
        end
      end

      def cache_read_multi(keys)
        return {} if keys.empty?

        values = with_connection { |conn| conn.mget(*keys) }.map do |value|
          value ? Marshal.load(value) : nil
        end

        Hash[keys.zip(values)]
      end

      def cache_write(key, value)
        with_connection { |conn| conn.setex(key, @ttl, Marshal.dump(value)) }
      end

      def cache_delete(key)
        with_connection { |conn| conn.del(key) }
      end
    end
  end
end
