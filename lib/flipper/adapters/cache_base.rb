module Flipper
  module Adapters
    # Base class for caching adapters. Inherit from this and then override
    # read_feature_keys, read_many_features, expire_features_cache
    # and expire_feature_cache.
    class CacheBase
      include ::Flipper::Adapter

      # Public: The adapter being cached.
      attr_reader :adapter

      # Public: The ActiveSupport::Cache::Store to cache with.
      attr_reader :cache

      # Public: The ttl for all cached data.
      attr_reader :ttl

      # Public: The cache key where the set of known features is cached.
      attr_reader :features_cache_key

      # Public: Alias expires_in to ttl for compatibility.
      alias_method :expires_in, :ttl

      def initialize(adapter, cache, ttl = 300, prefix: nil)
        @adapter = adapter
        @cache = cache
        @ttl = ttl

        @cache_version = 'v1'.freeze
        @namespace = "flipper/#{@cache_version}"
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
        read_feature(feature)
      end

      # Public
      def get_multi(features)
        read_many_features(features)
      end

      # Public
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
    end
  end
end
