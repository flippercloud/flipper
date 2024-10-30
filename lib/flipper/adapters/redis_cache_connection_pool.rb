require "redis"
require "flipper"

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter with the ability to cache
    # adapter calls in Redis
    class RedisCacheConnectionPool
      include ::Flipper::Adapter

      # Internal
      attr_reader :pool

      # Public
      def initialize(adapter, pool, ttl = 3600)
        @adapter = adapter
        @pool = pool
        @ttl = ttl

        @version = "v1"
        @namespace = "flipper/#{@version}"
        @features_key = "#{@namespace}/features"
        @get_all_key = "#{@namespace}/get_all"
      end

      # Public
      def features
        read_feature_keys
      end

      # Public
      def add(feature)
        result = @adapter.add(feature)
        @pool.with do |conn|
          conn.del(@features_key)
        end
        result
      end

      # Public
      def remove(feature)
        result = @adapter.remove(feature)
        @pool.with do |conn|
          conn.del(@features_key)
          conn.del(key_for(feature.key))
        end
        result
      end

      # Public
      def clear(feature)
        result = @adapter.clear(feature)
        @pool.with do |conn|
          conn.del(key_for(feature.key))
        end
        result
      end

      # Public
      def get(feature)
        fetch(key_for(feature.key)) do
          @adapter.get(feature)
        end
      end

      def get_multi(features)
        read_many_features(features)
      end

      def get_all
        @pool.with do |conn|
          if conn.setnx(@get_all_key, Time.now.to_i)
            conn.expire(@get_all_key, @ttl)
            response = @adapter.get_all
            response.each do |key, value|
              set_with_ttl key_for(key), value
            end
            set_with_ttl @features_key, response.keys.to_set
            response
          else
            features = read_feature_keys.map { |key| Flipper::Feature.new(key, self) }
            read_many_features(features)
          end
        end
      end

      # Public
      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        @pool.with do |conn|
          conn.del(key_for(feature.key))
        end
        result
      end

      # Public
      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        @pool.with do |conn|
          conn.del(key_for(feature.key))
        end
        result
      end

      private
        def key_for(key)
          "#{@namespace}/feature/#{key}"
        end

        def read_feature_keys
          fetch(@features_key) { @adapter.features }
        end

        def read_many_features(features)
          keys = features.map(&:key)
          cache_result = Hash[keys.zip(multi_cache_get(keys))]
          uncached_features = features.reject { |feature| cache_result[feature.key] }

          if uncached_features.any?
            response = @adapter.get_multi(uncached_features)
            response.each do |key, value|
              set_with_ttl(key_for(key), value)
              cache_result[key] = value
            end
          end

          result = {}
          features.each do |feature|
            result[feature.key] = cache_result[feature.key]
          end
          result
        end

        def fetch(cache_key)
          cached = @pool.with do |conn|
            conn.get(cache_key)
          end
          if cached
            Marshal.load(cached)
          else
            to_cache = yield
            set_with_ttl(cache_key, to_cache)
            to_cache
          end
        end

        def set_with_ttl(key, value)
          @pool.with do |conn|
            conn.setex(key, @ttl, Marshal.dump(value))
          end
        end

        def multi_cache_get(keys)
          return [] if keys.empty?

          cache_keys = keys.map { |key| key_for(key) }
          @pool.with do |conn|
            conn.mget(*cache_keys).map do |value|
              value ? Marshal.load(value) : nil
            end
          end
        end
    end
  end
end
