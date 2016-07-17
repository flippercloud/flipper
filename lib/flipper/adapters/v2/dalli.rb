require 'delegate'
require 'flipper'
require 'dalli'

module Flipper
  module Adapters
    module V2
      class Dalli
        include ::Flipper::Adapter

        # Internal
        attr_reader :cache

        # Public: The name of the adapter.
        attr_reader :name

        # Internal: The adapter this adapter is wrapping.
        attr_reader :adapter

        # Public
        def initialize(adapter, cache, ttl = 0)
          @adapter = adapter
          @name = :dalli
          @cache = cache
          @ttl = ttl
        end

        def version
          Adapter::V2
        end

        def get(key)
          cache.fetch(key, @ttl) { @adapter.get(key) }
        end

        def set(key, value)
          cache.delete(key)
          @adapter.set(key, value)
        end

        def del(key)
          cache.delete(key)
          @adapter.del(key)
        end
      end
    end
  end
end
