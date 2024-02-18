require 'flipper'
require 'flipper/adapters/cache_base'
require 'active_support/notifications'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in ActiveSupport::ActiveSupportCacheStore caches.
    class ActiveSupportCacheStore < CacheBase
      def initialize(adapter, cache, ttl = 300, expires_in: :none_provided, write_through: false, prefix: nil)
        if expires_in == :none_provided
          ttl ||= 300
        else
          warn "DEPRECATION WARNING: The `expires_in` kwarg is deprecated for " +
               "Flipper::Adapters::ActiveSupportCacheStore and will be removed " +
               "in the next major version. Please pass in expires in as third " +
               "argument instead."
          ttl = expires_in
        end
        super(adapter, cache, ttl, prefix: prefix)
        @write_through = write_through
      end

      def remove(feature)
        if @write_through
          result = @adapter.remove(feature)
          expire_features_cache
          cache_write feature_cache_key(feature.key), default_config
          result
        else
          super
        end
      end

      def enable(feature, gate, thing)
        if @write_through
          result = @adapter.enable(feature, gate, thing)
          cache_write feature_cache_key(feature.key), @adapter.get(feature)
          result
        else
          super
        end
      end

      def disable(feature, gate, thing)
        if @write_through
          result = @adapter.disable(feature, gate, thing)
          cache_write feature_cache_key(feature.key), @adapter.get(feature)
          result
        else
          super
        end
      end

      private

      def cache_fetch(key, &block)
        @cache.fetch(key, expires_in: @ttl, &block)
      end

      def cache_read_multi(keys)
        @cache.read_multi(*keys)
      end

      def cache_write(key, value)
        @cache.write(key, value, expires_in: @ttl)
      end

      def cache_delete(key)
        @cache.delete(key)
      end
    end
  end
end
