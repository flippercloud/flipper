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
          cache.fetch(FeaturesKey) { cache[FeaturesKey] = @adapter.features }
        else
          @adapter.features
        end
      end

      def add(feature)
        result = @adapter.add(feature)
        expire_features_set
        result
      end

      def remove(feature)
        result = @adapter.remove(feature)
        expire_features_set
        expire_feature(feature)
        result
      end

      def clear(feature)
        result = @adapter.clear(feature)
        expire_feature(feature)
        result
      end

      def get(feature)
        if memoizing?
          cache.fetch(feature.key) { cache[feature.key] = @adapter.get(feature) }
        else
          @adapter.get(feature)
        end
      end

      # Public
      def get_multi(features)
        if memoizing?
          uncached_features = features.reject { |feature| cache[feature.key] }

          if uncached_features.any?
            response = @adapter.get_multi(uncached_features)
            response.each do |key, hash|
              cache[key] = hash
            end
          end

          result = {}
          features.each do |feature|
            result[feature.key] = cache[feature.key]
          end
          result
        else
          @adapter.get_multi(features)
        end
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        expire_feature(feature)
        result
      end

      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        expire_feature(feature)
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

      private

      def expire_feature(feature)
        cache.delete(feature.key) if memoizing?
      end

      def expire_features_set
        cache.delete(FeaturesKey) if memoizing?
      end
    end
  end
end
