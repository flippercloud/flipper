require 'flipper'
require 'dalli'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Memcached using the Dalli gem.
    class Dalli
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Internal
      attr_reader :cache

      # Internal: The adapter this adapter is wrapping.
      attr_reader :adapter

      def initialize(adapter, cache, ttl = 0)
        @adapter = adapter
        @name = :dalli
        @cache = cache
        @ttl = ttl
      end

      def features
        @cache.fetch(FeaturesKey, @ttl) do
          @adapter.features
        end
      end

      def add(feature)
        result = @adapter.add(feature)
        @cache.delete(FeaturesKey)
        result
      end

      def remove(feature)
        result = @adapter.remove(feature)
        @cache.delete(FeaturesKey)
        result
      end

      def clear(feature)
        result = @adapter.clear(feature)
        @cache.delete(feature)
        result
      end

      def get(feature)
        @cache.fetch(feature, @ttl) do
          @adapter.get(feature)
        end
      end

      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        @cache.delete(feature)
        result
      end

      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        @cache.delete(feature)
        result
      end
    end
  end
end
