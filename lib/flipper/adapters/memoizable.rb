require 'delegate'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter with the ability to memoize
    # adapter calls in memory. Used by flipper dsl and the memoizer middleware
    # to make it possible to memoize adapter calls for the duration of a request.
    class Memoizable < SimpleDelegator
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features

      # Internal
      attr_reader :cache

      # Public: The name of the adapter.
      attr_reader :name

      # Internal: The adapter this adapter is wrapping.
      attr_reader :adapter

      # Public
      def initialize(adapter, cache = nil)
        super(adapter)
        @adapter = adapter
        @name = :memoizable
        @cache = cache || {}
        @memoize = false
      end

      # Public
      def features
        if memoizing?
          cache.fetch(FeaturesKey) {
            cache[FeaturesKey] = @adapter.features
          }
        else
          @adapter.features
        end
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        cache.delete(FeaturesKey) if memoizing?
        result
      end

      # Public
      def remove(feature)
        result = @adapter.remove(feature)
        if memoizing?
          cache.delete(FeaturesKey)
          cache.delete(feature)
        end
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        cache.delete(feature) if memoizing?
        result
      end

      # Public
      def get(feature)
        if memoizing?
          cache.fetch(feature) { cache[feature] = @adapter.get(feature) }
        else
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        if memoizing?
          missing_features = features.reject { |feature| cache[feature] }

          if missing_features.any?
            missing_hashes = @adapter.get_multi(missing_features)
            missing_features.zip(missing_hashes).each do |feature, hash|
              cache[feature] = hash
            end
          end

          features.map { |feature| cache[feature] }
        else
          @adapter.get_multi(features)
        end
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        cache.delete(feature) if memoizing?
        result
      end

      # Public
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
