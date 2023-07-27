require 'dalli'
require 'flipper'
require 'flipper/adapters/cache_base'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Memcached using the Dalli gem.
    class Dalli < CacheBase
      def initialize(adapter, cache, ttl = 300, prefix: nil)
        super
        @name = :dalli
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
        @cache.fetch(@features_cache_key, @ttl) { @adapter.features }
      end

      # Private: Given an array of features, attempts to read through cache in
      # as few network calls as possible.
      def read_many_features(features)
        keys = features.map { |feature| feature_cache_key(feature.key) }
        cache_result = @cache.get_multi(keys)
        uncached_features = features.reject { |feature| cache_result[feature_cache_key(feature.key)] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.set(feature_cache_key(key), value, @ttl)
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
        @cache.fetch(feature_cache_key(feature.key), @ttl) do
          @adapter.get(feature)
        end
      end
    end
  end
end
