require 'redis'
require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Redis.
    class RedisCache
      include ::Flipper::Adapter

      # Public: The adapter being cached.
      attr_reader :adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The Redis instance to cache with.
      attr_reader :cache

      # Public: The ttl for all cached data.
      attr_reader :ttl

      alias_method :expires_in, :ttl

      # Public
      def initialize(adapter, cache, ttl = 3600, prefix: nil)
        @adapter = adapter
        @name = :redis_cache
        @cache = cache
        @ttl = ttl

        @version = 'v1'.freeze
        @namespace = "flipper/#{@version}"
        @namespace = @namespace.prepend(prefix) if prefix
        @features_cache_key = "#{@namespace}/features"
      end

      # Public
      def features
        read_feature_keys
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        expire_features_cache
        result
      end

      # Public
      def remove(feature)
        result = @adapter.remove(feature)
        expire_features_cache
        expire_feature_cache(feature.key)
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        expire_feature_cache(feature.key)
        result
      end

      # Public
      def get(feature)
        fetch(feature_cache_key(feature.key)) do
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all
        features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
        read_many_features(features)
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        expire_feature_cache(feature.key)
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        expire_feature_cache(feature.key)
        result
      end

      # Public: Generate the cache key for a given feature.
      #
      # key - The String or Symbol feature key.
      def feature_cache_key(key)
        "#{@namespace}/feature/#{key}"
      end

      # Public: Expire the cache for the set of known feature names.
      def expire_features_cache
        @cache.del(@features_cache_key)
      end

      # Public: Expire the cache for a given feature.
      def expire_feature_cache(key)
        @cache.del(feature_cache_key(key))
      end

      private

      def read_feature_keys
        fetch(@features_cache_key) { @adapter.features }
      end

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
