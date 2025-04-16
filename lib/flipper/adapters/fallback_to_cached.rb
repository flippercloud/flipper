require 'flipper/adapters/memoizable'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and caches the result of all
    # adapter get calls in memory. If the primary adapter raises an error, the
    # cached value will be used instead.
    class FallbackToCached < Memoizable
      def initialize(adapter, cache = nil)
        super
        @memoize = true
      end

      def memoize=(value)
        # noop
      end

      # Public: The set of known features.
      #
      # Returns a set of features.
      def features
        response = @adapter.features
        cache[@features_key] = response
        response
      rescue => e
        cache[@features_key] || raise(e)
      end

      # Public: Gets the value for a feature from the primary adapter. If the
      # primary adapter raises an error, the cached value will be returned
      # instead.
      #
      # feature - The feature to get the value for.
      #
      # Returns the value for the feature.
      def get(feature)
        cache[key_for(feature.key)] = @adapter.get(feature)
      rescue => e
        cache[key_for(feature.key)] || raise(e)
      end

      # Public: Gets the values for multiple features from the primary adapter.
      # If the primary adapter raises an error, the cached values will be
      # returned instead.
      #
      # features - The features to get the values for.
      #
      # Returns a hash of feature keys to values.
      def get_multi(features)
        response = @adapter.get_multi(features)
        cache.clear
        features.each do |feature|
          cache[key_for(feature.key)] = response[feature.key]
        end
        response
      rescue => e
        result = {}
        features.each do |feature|
          result[feature.key] = cache[key_for(feature.key)] || raise(e)
        end
        result
      end

      # Public: Gets all the values from the primary adapter. If the primary
      # adapter raises an error, the cached values will be returned instead.
      #
      # Returns a hash of feature keys to values.
      def get_all
        response = @adapter.get_all
        cache.clear
        response.each do |key, value|
          cache[key_for(key)] = value
        end
        cache[@features_key] = response.keys.to_set
        response
      rescue => e
        raise e if cache[@features_key].empty?
        response = {}
        cache[@features_key].each do |key|
          response[key] = cache[key_for(key)]
        end
        response
      end
    end
  end
end
