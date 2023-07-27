require 'flipper'
require 'active_support/notifications'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in ActiveSupport::ActiveSupportCacheStore caches.
    class ActiveSupportCacheStore
      include ::Flipper::Adapter

      # Public: The adapter being cached.
      attr_reader :adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The ActiveSupport::Cache::Store to cache with.
      attr_reader :cache

      # Public: The number of seconds cached data should expire in.
      attr_reader :expires_in

      alias_method :ttl, :expires_in

      # Public
      def initialize(adapter, cache, expires_in: nil, write_through: false, prefix: nil)
        @adapter = adapter
        @name = :active_support_cache_store
        @cache = cache
        @expires_in = expires_in
        @write_through = write_through

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

      ## Public
      def remove(feature)
        result = @adapter.remove(feature)
        expire_features_cache

        if @write_through
          @cache.write(feature_cache_key(feature.key), default_config, expires_in: @expires_in)
        else
          expire_feature_cache(feature.key)
        end

        result
      end

      ## Public
      def clear(feature)
        result = @adapter.clear(feature)
        expire_feature_cache(feature.key)
        result
      end

      ## Public
      def get(feature)
        @cache.fetch(feature_cache_key(feature.key), expires_in: @expires_in) do
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

      ## Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)

        if @write_through
          @cache.write(feature_cache_key(feature.key), @adapter.get(feature), expires_in: @expires_in)
        else
          expire_feature_cache(feature.key)
        end

        result
      end

      ## Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)

        if @write_through
          @cache.write(feature_cache_key(feature.key), @adapter.get(feature), expires_in: @expires_in)
        else
          expire_feature_cache(feature.key)
        end

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

      # Internal: Returns an array of the known feature keys.
      def read_feature_keys
        @cache.fetch(@features_cache_key, expires_in: @expires_in) { @adapter.features }
      end

      # Internal: Given an array of features, attempts to read through cache in
      # as few network calls as possible.
      def read_many_features(features)
        keys = features.map { |feature| feature_cache_key(feature.key) }
        cache_result = @cache.read_multi(*keys)
        uncached_features = features.reject { |feature| cache_result[feature_cache_key(feature)] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.write(feature_cache_key(key), value, expires_in: @expires_in)
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
