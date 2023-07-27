require 'dalli'
require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Memcached using the Dalli gem.
    class Dalli
      include ::Flipper::Adapter

      # Public: The adapter being cached.
      attr_reader :adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The Dalli::Client instance to cache with.
      attr_reader :cache

      # Public: The ttl for all cached data.
      attr_reader :ttl

      alias_method :expires_in, :ttl

      # Public
      def initialize(adapter, cache, ttl = 0, prefix: nil)
        @adapter = adapter
        @name = :dalli
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
        @cache.fetch(feature_cache_key(feature.key), @ttl) do
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
        @cache.delete(@features_cache_key)
      end

      # Public: Expire the cache for a given feature.
      def expire_feature_cache(key)
        @cache.delete(feature_cache_key(key))
      end

      private

      def read_feature_keys
        @cache.fetch(@features_cache_key, @ttl) { @adapter.features }
      end

      # Internal: Given an array of features, attempts to read through cache in
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
    end
  end
end
