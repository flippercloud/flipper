require 'dalli'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Memcached using the Dalli gem.
    class Dalli
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features

      # Internal
      attr_reader :cache

      # Public: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter, cache, ttl = 0)
        @adapter = adapter
        @name = :dalli
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
        @cache.delete(feature)
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        @cache.delete(feature)
        result
      end

      # Public
      def get(feature)
        @cache.fetch(feature, @ttl) do
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        result = @cache.get_multi(features)
        uncached_features = features.reject { |feature| result[feature] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.set(key, value, @ttl)
            result[key] = value
          end
        end

        result
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        @cache.delete(feature)
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        @cache.delete(feature)
        result
      end
    end
  end
end
