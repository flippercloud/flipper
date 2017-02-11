require 'delegate'
require 'flipper'

module Flipper
  module Adapters
    module V2
      # Internal: Adapter that wraps another adapter with the ability to memoize
      # adapter calls in memory. Used by flipper dsl and the memoizer middleware
      # to make it possible to memoize adapter calls for the duration of a request.
      class Memoizable < SimpleDelegator
        include ::Flipper::Adapter

        # Public: The name of the adapter.
        attr_reader :name

        # Internal
        attr_reader :cache

        # Internal: The adapter this adapter is wrapping.
        attr_reader :adapter

        # Public
        def initialize(adapter, cache = nil)
          super(adapter)
          @adapter = adapter
          @name = :memoizable
          @cache = cache || {}
          @memoize = false
        end

        def version
          Adapter::V2
        end

        def get(key)
          if memoizing?
            cache.fetch(key) do
              cache[key] = @adapter.get(key)
            end
          else
            @adapter.get(key)
          end
        end

        def set(key, value)
          cache.delete(key) if memoizing?
          @adapter.set(key, value)
        end

        def del(key)
          cache.delete(key) if memoizing?
          @adapter.del(key)
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
          @memoize
        end
      end
    end
  end
end
