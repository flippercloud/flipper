require 'forwardable'

module Flipper
  module Adapters
    class Memoized
      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Public: The adapter that is being memoized.
      attr_reader :adapter

      # Private: The memoized cache of adapter operations and results.
      attr_reader :cache

      # Public
      def initialize(adapter, cache = {})
        @adapter = adapter
        @name = :memoized
        @cache = cache
      end

      # Public
      def get(feature)
        @cache.fetch(feature) {
          @cache[feature] = @adapter.get(feature)
        }
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

      def features
        @cache.fetch(FeaturesKey) {
          @cache[FeaturesKey] = @adapter.features
        }
      end

      def add(feature)
        result = @adapter.add(feature)
        @cache.delete(FeaturesKey)
        result
      end

      def unmemoize
        @cache.clear
      end

      def inspect
        attributes = [
          "name=#{name.inspect}",
          "adapter=#{adapter.inspect}",
          "cache=#{@cache.inspect}",
        ]
        "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
      end
    end
  end
end
