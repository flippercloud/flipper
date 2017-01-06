require 'redis'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Redis
    class RedisCache
      include ::Flipper::Adapter

      Version = "v1".freeze
      Namespace = "flipper/#{Version}".freeze
      FeaturesKey = "#{Namespace}/features".freeze

      # Private
      def self.key_for(key)
        "#{Namespace}/feature/#{key}"
      end

      # Internal
      attr_reader :cache

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter, cache, ttl = 3600)
        @adapter = adapter
        @name = :redis
        @cache = cache
        @ttl = ttl
      end

      # Public
      def features
        @cache.fetch(FeaturesKey, @ttl) do
          @adapter.features
        end
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        @cache.delete(FeaturesKey)
        result
      end

      # Public
      def remove(feature)
        result = @adapter.remove(feature)
        @cache.delete(FeaturesKey)
        @cache.delete(key_for(feature.key))
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        @cache.delete(key_for(feature.key))
        result
      end

      # Public
      def get(feature)
        @cache.fetch(key_for(feature.key), @ttl) do
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        keys = features.map { |feature| key_for(feature.key) }
        result = @cache.get_multi(keys)
        uncached_features = features.reject { |feature| result[key_for(feature.key)] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.set(key_for(key), value, @ttl)
            result[key] = value
          end
        end

        result
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        @cache.delete(key_for(feature.key))
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        @cache.delete(key_for(feature.key))
        result
      end

      private

      def key_for(key)
        self.class.key_for(key)
      end
    end
  end
end
