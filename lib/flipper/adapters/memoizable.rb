require 'delegate'
require 'flipper'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter with the ability to memoize
    # adapter calls in memory. Used by flipper dsl and the memoizer middleware
    # to make it possible to memoize adapter calls for the duration of a request.
    class Memoizable < SimpleDelegator
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features

      # Public: The name of the adapter.
      attr_reader :name

      # Internal
      attr_reader :cache

      # Internal: The adapter this adapter is wrapping.
      attr_reader :adapter

      def initialize(adapter, cache = nil)
        super(adapter)
        @adapter = adapter
        @name = :memoizable
        @cache = cache || {}
        @memoize = false
      end

      def features
        if memoizing?
          cache.fetch(FeaturesKey) {
            cache[FeaturesKey] = @adapter.features
          }
        else
          @adapter.features
        end
      end

      def add(feature)
        result = @adapter.add(feature)
        cache.delete(FeaturesKey) if memoizing?
        result
      end

      def remove(feature)
        result = @adapter.remove(feature)
        if memoizing?
          cache.delete(FeaturesKey)
          cache.delete(feature)
        end
        result
      end

      def clear(feature)
        result = @adapter.clear(feature)
        cache.delete(feature) if memoizing?
        result
      end

      def get(feature)
        if memoizing?
          cache.fetch(feature) { cache[feature] = @adapter.get(feature) }
        else
          @adapter.get(feature)
        end
      end

      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        cache.delete(feature) if memoizing?
        result
      end

      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        cache.delete(feature) if memoizing?
        result
      end

      # Internal: Turns local caching on/off.
      #
      # value - The Boolean that decides if local caching is on.
      def memoize=(value)
        cache.clear
        @memoize = value
      end

      # Internal: Returns true for using local cache, false for not.
      def memoizing?
        !!@memoize
      end
    end
  end
end
