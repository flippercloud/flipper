require 'dalli'
require 'flipper'
require 'flipper/adapters/cache_base'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Memcached using the Dalli gem.
    class Dalli < CacheBase
      private

      def cache_fetch(key, &block)
        @cache.fetch(key, @ttl, &block)
      end

      def cache_read_multi(keys)
        @cache.get_multi(keys)
      end

      def cache_write(key, value)
        @cache.set(key, value, @ttl)
      end

      def cache_delete(key)
        @cache.delete(key)
      end
    end
  end
end
