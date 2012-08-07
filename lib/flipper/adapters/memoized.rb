require 'set'

module Flipper
  module Adapters
    class Memoized
      def initialize(adapter, cache = {})
        @adapter = adapter
        @cache = cache
      end

      def read(key)
        @cache.fetch(key) {
          @cache[key] = @adapter.read(key)
        }
      end

      def write(key, value)
        result = @adapter.write(key, value)
        @cache.delete(key)
        result
      end

      def delete(key)
        result = @adapter.delete(key)
        @cache.delete(key)
        result
      end

      def set_add(key, value)
        result = @adapter.set_add(key, value)
        @cache.delete(key)
        result
      end

      def set_delete(key, value)
        result = @adapter.set_delete(key, value)
        @cache.delete(key)
        result
      end

      def set_members(key)
        @cache.fetch(key) {
          @cache[key] = @adapter.set_members(key)
        }
      end
    end
  end
end
