require 'redis'
require 'flipper'
require 'flipper/adapters/cache_base'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Redis.
    class RedisCache < CacheBase
      def initialize(adapter, cache, ttl = 3600, prefix: nil)
        super
      end

      private

      def cache_fetch(key, &block)
        cached = @cache.get(key)
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

        values = @cache.mget(*keys).map do |value|
          value ? Marshal.load(value) : nil
        end

        Hash[keys.zip(values)]
      end

      def cache_write(key, value)
        @cache.setex(key, @ttl, Marshal.dump(value))
      end

      def cache_delete(key)
        @cache.del(key)
      end
    end
  end
end
