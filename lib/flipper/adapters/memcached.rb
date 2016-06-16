require 'pry'
require 'dalli'

module Flipper
  module Adapters
    class Memcached
      include Flipper::Adapter
      attr_accessor :cache
      attr_accessor :name
      FeaturesKey =  :flipper_features

      def initialize(adapter, address = 'localhost:11211', options = {})
        @adapter = adapter
        @name = adapter.name
        @cache = Dalli::Client.new(address, options) 
      end

      def features
        result = @cache.get(FeaturesKey)
        return result if result
        features = @adapter.features
        @cache.set(FeaturesKey, features)
        features
      end

      def add(feature)
        result = @adapter.add(feature)
        @cache.delete(FeaturesKey)
        result
      end

      def remove(feature)
        result = @adapter.remove(feature)
        @cache.delete(FeaturesKey)
        result
      end

      def clear(feature = nil)
        return @cache.flush if feature.nil?
        result = @adapter.clear(feature)
        @cache.delete(feature)
        result
      end

      def get(feature)
        @adapter.get(feature)
        #if @cache.get(feature)
        #  @cache.get(feature)
        #else
        #  result = @adapter.get(feature)
        #  @cache.set(feature, result)
        #  result
        #end
      end

      def []=(key, value)
        @cache.set(key, value)
      end

      def enable(feature, gate, thing)
        result = @adapter.enable(feature, gate, thing)
        @cache.delete(feature)
        result
      end

      def disable(feature, gate, thing)
        result = @adapter.disable(feature, gate, thing)
        @cache.delete(feature)
        result
      end
    end
  end
end
