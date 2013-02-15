require 'forwardable'

module Flipper
  module Adapters
    class Memoized
      extend Forwardable

      FeaturesKey = :flipper_features

      # Forward soon to be private adapter methods to source adapter
      def_delegators :@adapter, :read, :write, :delete,
        :set_members, :set_add, :set_delete

      # Public
      def initialize(adapter, cache = {})
        @adapter = adapter
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
    end
  end
end
