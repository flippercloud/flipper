require 'delegate'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter with the ability to memoize
    # adapter calls in memory. Used by flipper dsl and the memoizer middleware
    # to make it possible to memoize adapter calls for the duration of a request.
    class Memoizable
      include ::Flipper::Adapter

      # Internal
      attr_reader :cache

      # Internal: The adapter this adapter is wrapping.
      attr_reader :adapter

      # Public
      def initialize(adapter, cache = nil)
        @adapter = adapter
        @cache = cache || {}
        @memoize = false
        @features_key = :flipper_features
        @get_all_key = :all_memoized
      end

      # Public
      def features
        if memoizing?
          cache.fetch(@features_key) { cache[@features_key] = @adapter.features }
        else
          @adapter.features
        end
      end

      # Public
      def add(feature)
        @adapter.add(feature).tap { expire_features_set }
      end

      # Public
      def remove(feature)
        @adapter.remove(feature).tap do
          expire_features_set
          expire_feature(feature)
        end
      end

      # Public
      def clear(feature)
        @adapter.clear(feature).tap { expire_feature(feature) }
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
        if memoizing?
          response = nil
          if cache[@get_all_key]
            response = {}
            cache[@features_key].each do |key|
              response[key] = cache[key_for(key)]
            end
          else
            response = @adapter.get_all
            response.each do |key, value|
              cache[key_for(key)] = value
            end
            cache[@features_key] = response.keys.to_set
            cache[@get_all_key] = true
          end

          # Ensures that looking up other features that do not exist doesn't
          # result in N+1 adapter calls.
          response.default_proc = ->(memo, key) { memo[key] = default_config }
          response
        else
          @adapter.get_all
        end
      end

      # Public
      def enable(feature, gate, thing)
        @adapter.enable(feature, gate, thing).tap { expire_feature(feature) }
      end

      # Public
      def disable(feature, gate, thing)
        @adapter.disable(feature, gate, thing).tap { expire_feature(feature) }
      end

      # Public
      def read_only?
        @adapter.read_only?
      end

      def import(source)
        @adapter.import(source).tap { cache.clear if memoizing? }
      end

      def export(format: :json, version: 1)
        @adapter.export(format: format, version: version)
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

      if RUBY_VERSION >= '3.0'
        def method_missing(name, *args, **kwargs, &block)
          @adapter.send name, *args, **kwargs, &block
        end
      else
        def method_missing(name, *args, &block)
          @adapter.send name, *args, &block
        end
      end

      private

      def key_for(key)
        "feature/#{key}"
      end

      def expire_feature(feature)
        cache.delete(key_for(feature.key)) if memoizing?
      end

      def expire_features_set
        cache.delete(@features_key) if memoizing?
      end
    end
  end
end
