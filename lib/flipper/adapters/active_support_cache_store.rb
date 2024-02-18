require 'flipper'
require 'flipper/adapters/cache_base'
require 'active_support/notifications'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in ActiveSupport::ActiveSupportCacheStore caches.
    class ActiveSupportCacheStore < CacheBase
      include ::Flipper::Adapter

      def initialize(adapter, cache, expires_in: 300, write_through: false, prefix: nil)
        super(adapter, cache, expires_in, prefix: prefix)
        @write_through = write_through
      end

      def remove(feature)
        if @write_through
          result = @adapter.remove(feature)
          expire_features_cache
          @cache.write(feature_cache_key(feature.key), default_config, expires_in: @ttl)
          result
        else
          super
        end
      end

      def enable(feature, gate, thing)
        if @write_through
          result = @adapter.enable(feature, gate, thing)
          @cache.write(feature_cache_key(feature.key), @adapter.get(feature), expires_in: @ttl)
          result
        else
          super
        end
      end

      def disable(feature, gate, thing)
        if @write_through
          result = @adapter.disable(feature, gate, thing)
          @cache.write(feature_cache_key(feature.key), @adapter.get(feature), expires_in: @ttl)
          result
        else
          super
        end
      end

      # Public: Generate the cache key for a given feature.
      #
      # key - The String or Symbol feature key.
      def feature_cache_key(key)
        "#{@namespace}/feature/#{key}"
      end

      # Public: Expire the cache for the set of known feature names.
      def expire_features_cache
        @cache.delete(@features_cache_key)
      end

      # Public: Expire the cache for a given feature.
      def expire_feature_cache(key)
        @cache.delete(feature_cache_key(key))
      end

      private

      # Private: Returns the Set of known feature keys.
      def read_feature_keys
        @cache.fetch(@features_cache_key, expires_in: @ttl) { @adapter.features }
      end

      # Private: Given an array of features, attempts to read through cache in
      # as few network calls as possible.
      def read_many_features(features)
        keys = features.map { |feature| feature_cache_key(feature.key) }
        cache_result = @cache.read_multi(*keys)
        uncached_features = features.reject { |feature| cache_result[feature_cache_key(feature)] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.write(feature_cache_key(key), value, expires_in: @ttl)
            cache_result[feature_cache_key(key)] = value
          end
        end

        result = {}
        features.each do |feature|
          result[feature.key] = cache_result[feature_cache_key(feature.key)]
        end
        result
      end

      def read_feature(feature)
        @cache.fetch(feature_cache_key(feature.key), expires_in: @ttl) do
          @adapter.get(feature)
        end
      end
    end
  end
end
