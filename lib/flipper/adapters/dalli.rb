require 'dalli'
require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Memcached using the Dalli gem.
    class Dalli
      include ::Flipper::Adapter

      # Internal
      attr_reader :cache

      # Public: The ttl for all cached data.
      attr_reader :ttl

      # Public
      def initialize(adapter, cache, ttl = 0)
        @adapter = adapter
        @cache = cache
        @ttl = ttl

        @cache_version = 'v1'.freeze
        @namespace = "flipper/#{@cache_version}".freeze
        @features_key = "#{@namespace}/features".freeze
        @get_all_key = "#{@namespace}/get_all".freeze
      end

      # Public
      def features
        read_feature_keys
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        @cache.delete(@features_key)
        result
      end

      # Public
      def remove(feature)
        result = @adapter.remove(feature)
        @cache.delete(@features_key)
        @cache.delete(key_for(feature.key))
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        @cache.delete(key_for(feature.key))
        result
      end

      # Public
      def get(feature)
        @cache.fetch(key_for(feature.key), @ttl) do
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all
        if @cache.add(@get_all_key, Time.now.to_i, @ttl)
          response = @adapter.get_all
          response.each do |key, value|
            @cache.set(key_for(key), value, @ttl)
          end
          @cache.set(@features_key, response.keys.to_set, @ttl)
          response
        else
          features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
          read_many_features(features)
        end
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        @cache.delete(key_for(feature.key))
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        @cache.delete(key_for(feature.key))
        result
      end

      private

      def key_for(key)
        "#{@namespace}/feature/#{key}"
      end

      def read_feature_keys
        @cache.fetch(@features_key, @ttl) { @adapter.features }
      end

      # Internal: Given an array of features, attempts to read through cache in
      # as few network calls as possible.
      def read_many_features(features)
        keys = features.map { |feature| key_for(feature.key) }
        cache_result = @cache.get_multi(keys)
        uncached_features = features.reject { |feature| cache_result[key_for(feature.key)] }

        if uncached_features.any?
          response = @adapter.get_multi(uncached_features)
          response.each do |key, value|
            @cache.set(key_for(key), value, @ttl)
            cache_result[key_for(key)] = value
          end
        end

        result = {}
        features.each do |feature|
          result[feature.key] = cache_result[key_for(feature.key)]
        end
        result
      end
    end
  end
end
