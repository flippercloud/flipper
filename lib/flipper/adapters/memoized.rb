require 'flipper/adapters/decorator'

module Flipper
  module Adapters
    class Memoized < Decorator
      FeaturesKey = :flipper_features

      # Private: The cache of adapter operations and results.
      attr_reader :cache

      # Public
      def initialize(adapter, cache = {})
        super(adapter)
        @cache = cache
      end

      # Public
      def get(feature)
        @cache.fetch(feature) {
          @cache[feature] = super
        }
      end

      # Public
      def enable(feature, gate, thing)
        result = super
        @cache.delete(feature)
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = super
        @cache.delete(feature)
        result
      end

      def features
        @cache.fetch(FeaturesKey) {
          @cache[FeaturesKey] = super
        }
      end

      def add(feature)
        result = super
        @cache.delete(FeaturesKey)
        result
      end
    end
  end
end
