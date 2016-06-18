require 'flipper/adapters/v2/set_interface'
require 'flipper/adapters/v2/multi_interface'

module Flipper
  module Adapters
    module V2
      # Internal: Adapter that wraps another adapter with the ability to memoize
      # adapter calls in memory. Used by flipper dsl and the memoizer middleware
      # to make it possible to memoize adapter calls for the duration of a request.
      class Memoizable
        include ::Flipper::Adapter
        include ::Flipper::Adapters::V2::MultiInterface
        include ::Flipper::Adapters::V2::SetInterface

        # Internal
        attr_reader :cache

        # Public: The name of the adapter.
        attr_reader :name

        # Internal: The adapter this adapter is wrapping.
        attr_reader :adapter

        # Public
        def initialize(adapter, cache = nil)
          @adapter = adapter
          @name = :memoizable
          @cache = cache || {}
          @memoize = false
        end

        def version
          V2
        end

        def get(key)
          if memoizing?
            cache.fetch(key) {
              cache[key] = @adapter.get(key)
            }
          else
            @adapter.get(key)
          end
        end

        def mget(keys)
          if memoizing?
            cached, missing = keys.partition { |key| cache.key?(key) }
            result = {}
            cached.each { |key| result[key] = cache[key] }

            if missing.any?
              adapter_values = @adapter.mget(missing)
              adapter_values.each { |key, value|
                result[key] = value
                cache[key] = value
              }
            end

            result
          else
            @adapter.mget(keys)
          end
        end

        def set(key, value)
          cache.delete(key) if memoizing?
          @adapter.set(key, value)
        end

        def mset(kvs)
          kvs.each { |key, value| cache.delete(key) } if memoizing?
          @adapter.mset(kvs)
        end

        def del(key)
          cache.delete(key) if memoizing?
          @adapter.del(key)
        end

        def mdel(keys)
          keys.each { |key| cache.delete(key) } if memoizing?
          @adapter.mdel(keys)
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
      end
    end
  end
end
