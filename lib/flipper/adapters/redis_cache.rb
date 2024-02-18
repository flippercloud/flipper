require 'redis'
require 'flipper'
require 'flipper/adapters/cache_base'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Redis.
    class RedisCache < CacheBase
      # Public: Expire the cache for the set of known feature names.
      def expire_features_cache
        @cache.del(@features_cache_key)
      end

      # Public: Expire the cache for a given feature.
      def expire_feature_cache(key)
        @cache.del(feature_cache_key(key))
      end

      private

      # Private: Returns the Set of known feature keys.
      def read_feature_keys
        fetch(@features_cache_key) { @adapter.features }
      end

      # Private: Given an array of features, attempts to read through cache in
      # as few network calls as possible.
      def read_many_features(features)
        keys = features.map(&:key)
        cache_result = Hash[keys.zip(multi_cache_get(keys))]
        uncached_features = features.reject { |feature| cache_result[feature.key] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            set_with_ttl(feature_cache_key(key), value)
            cache_result[key] = value
          end
        end

        result = {}
        features.each do |feature|
          result[feature.key] = cache_result[feature.key]
        end
        result
      end

      def read_feature(feature)
        fetch(feature_cache_key(feature.key)) do
          @adapter.get(feature)
        end
      end

      def fetch(cache_key)
        cached = @cache.get(cache_key)
        if cached
          Marshal.load(cached)
        else
          to_cache = yield
          set_with_ttl(cache_key, to_cache)
          to_cache
        end
      end

      def set_with_ttl(key, value)
        @cache.setex(key, @ttl, Marshal.dump(value))
      end

      def multi_cache_get(keys)
        return [] if keys.empty?

        cache_keys = keys.map { |key| feature_cache_key(key) }
        @cache.mget(*cache_keys).map do |value|
          value ? Marshal.load(value) : nil
        end
      end
    end
  end
end
