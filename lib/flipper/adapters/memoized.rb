require 'flipper/adapters/decorator'

module Flipper
  module Adapters
    class Memoizable < Decorator
      FeaturesKey = :flipper_features

      # Private: The cache of memoized adapter operations and results.
      attr_reader :cache

      # Public
      def initialize(adapter, cache = nil)
        super(adapter)
        @cache = cache || {}
      end

      # Public: Turns local caching on/off.
      #
      # value - The Boolean that decides if local caching is on.
      def memoize=(value)
        cache.clear
        @memoize = value
      end

      # Public: Returns true for using local cache, false for not.
      def memoizing?
        !!@memoize
      end

      # Public
      def get(feature)
        if memoizing?
          @cache.fetch(feature) { @cache[feature] = super }
        else
          super
        end
      end

      # Public
      def enable(feature, gate, thing)
        result = super
        @cache.delete(feature) if memoizing?
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = super
        @cache.delete(feature) if memoizing?
        result
      end

      # Public
      def features
        if memoizing?
          @cache.fetch(FeaturesKey) {
            @cache[FeaturesKey] = super
          }
        else
          super
        end
      end

      # Public
      def add(feature)
        result = super
        @cache.delete(FeaturesKey) if memoizing?
        result
      end
    end
  end
end
