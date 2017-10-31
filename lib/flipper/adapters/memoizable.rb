require 'delegate'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter with the ability to memoize
    # adapter calls in memory. Used by flipper dsl and the memoizer middleware
    # to make it possible to memoize adapter calls for the duration of a request.
    class Memoizable < SimpleDelegator
      include ::Flipper::Adapter

      FeaturesKey = :flipper_features
      GetAllKey = :all_memoized

      # Internal
      attr_reader :cache

      # Public: The name of the adapter.
      attr_reader :name

      # Internal: The adapter this adapter is wrapping.
      attr_reader :adapter

      # Private
      def self.key_for(key)
        "feature/#{key}"
      end

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
          cache.fetch(FeaturesKey) { cache[FeaturesKey] = @adapter.features }
        else
          @adapter.features
        end
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        expire_features_set
        result
      end

      # Public
      def remove(feature)
        result = @adapter.remove(feature)
        expire_features_set
        expire_feature(feature)
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        expire_feature(feature)
        result
      end

      # Public
      def get(feature)
        if memoizing?
          cache.fetch(key_for(feature.key)) { cache[key_for(feature.key)] = @adapter.get(feature) }
        else
          @adapter.get(feature)
        end
      end

      # Public
      def get_multi(features)
        if memoizing?
          uncached_features = features.reject { |feature| cache[key_for(feature.key)] }

          if uncached_features.any?
            response = @adapter.get_multi(uncached_features)
            response.each do |key, hash|
              cache[key_for(key)] = hash
            end
          end

          result = {}
          features.each do |feature|
            result[feature.key] = cache[key_for(feature.key)]
          end
          result
        else
          @adapter.get_multi(features)
        end
      end

      def get_all
        response = if memoizing?
          if cache[GetAllKey]
            hash = {}
            cache[FeaturesKey].each do |key|
              hash[key] = cache[key_for(key)]
            end
            hash
          else
            adapter_response = @adapter.get_all
            adapter_response.each do |key, hash|
              cache[key_for(key)] = hash
            end
            cache[FeaturesKey] = adapter_response.keys.to_set
            cache[GetAllKey] = true
            adapter_response
          end
        else
          @adapter.get_all
        end

        # Ensures that looking up other features that do not exist doesn't
        # result in N+1 adapter calls.
        response.default_proc = ->(hash, key) { hash[key] = default_config }
        response
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        expire_feature(feature)
        result
      end

      # Public
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

      def key_for(key)
        self.class.key_for(key)
      end

      def expire_feature(feature)
        cache.delete(key_for(feature.key)) if memoizing?
      end

      def expire_features_set
        cache.delete(FeaturesKey) if memoizing?
      end
    end
  end
end
