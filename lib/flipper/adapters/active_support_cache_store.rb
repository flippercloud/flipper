require 'flipper'
require 'flipper/adapters/cache_base'
require 'active_support/notifications'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in ActiveSupport::ActiveSupportCacheStore caches.
    class ActiveSupportCacheStore < CacheBase

      # Public: The race_condition_ttl for all cached data.
      attr_reader :race_condition_ttl

      def initialize(adapter, cache, ttl = nil, expires_in: :none_provided, race_condition_ttl: nil, write_through: false, prefix: nil)
        if expires_in == :none_provided
          ttl ||= nil
        else
          warn "DEPRECATION WARNING: The `expires_in` kwarg is deprecated for " +
               "Flipper::Adapters::ActiveSupportCacheStore and will be removed " +
               "in the next major version. Please pass in expires in as third " +
               "argument instead."
          ttl = expires_in
        end
        super(adapter, cache, ttl, prefix: prefix)
        @race_condition_ttl = race_condition_ttl
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
        @cache.fetch(key, write_options, &block)
      end

      def cache_read_multi(keys)
        @cache.read_multi(*keys)
      end

      def cache_write(key, value)
        @cache.write(key, value, write_options)
      end

      def cache_delete(key)
        @cache.delete(key)
      end

      def write_options
        write_options = {}
        write_options[:expires_in] = @ttl if @ttl
        write_options[:race_condition_ttl] if @race_condition_ttl
        write_options
      end
    end
  end
end
