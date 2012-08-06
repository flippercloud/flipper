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
        @cache.delete(key)
        @adapter.write(key, value)
      end

      def delete(key)
        @cache.delete(key)
        @adapter.delete(key)
      end

      def set_add(key, value)
        @cache.delete(key)
        @adapter.set_add(key, value)
      end

      def set_delete(key, value)
        @cache.delete(key)
        @adapter.set_delete(key, value)
      end

      def set_members(key)
        @cache.fetch(key) {
          @cache[key] = @adapter.set_members(key)
        }
      end
    end
  end
end
