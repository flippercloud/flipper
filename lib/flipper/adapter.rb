require 'flipper/adapters/decorator'
require 'flipper/instrumenters/noop'

module Flipper
  # Internal: Adapter wrapper that wraps vanilla adapter instances. Adds things
  # like local caching and instrumentation.
  #
  # So what is this local cache crap?
  #
  # The main goal of the local cache is to prevent multiple queries to an
  # adapter for the same key for a given amount of time (per request, per
  # background job, etc.).
  #
  # To facilitate with this, there is an included local cache middleware
  # that enables local caching for the length of a web request. The local
  # cache is enabled and cleared before each request and cleared and reset
  # to original value after each request.
  #
  # Examples
  #
  # To see an example adapter that this would wrap, checkout the [memory
  # adapter included with flipper](https://github.com/jnunemaker/flipper/blob/master/lib/flipper/adapters/memory.rb).
  class Adapter < Adapters::Decorator
    # Private: What adapter is being wrapped and will ultimately be used.
    attr_reader :adapter

    # Private: What is used to store the operation cache.
    attr_reader :local_cache

    # Private: What is instrumenting all the operations.
    attr_reader :instrumenter

    # Internal: Initializes a new adapter instance.
    #
    # adapter - Vanilla adapter instance to wrap. Just needs to respond to get,
    #           enable and disable.
    #
    # options - The Hash of options.
    #           :local_cache - Where to store the local cache data (default: {}).
    #                          Must respond to fetch(key, block), delete(key)
    #                          and clear.
    def initialize(adapter, options = {})
      @local_cache = options[:local_cache] || {}
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      @adapter = Adapters::Instrumented.new(adapter, {
        :instrumenter => @instrumenter,
      })

      super @adapter
    end

    # Public: Turns local caching on/off.
    #
    # value - The Boolean that decides if local caching is on.
    def use_local_cache=(value)
      local_cache.clear
      @use_local_cache = value
    end

    # Public: Returns true for using local cache, false for not.
    def using_local_cache?
      @use_local_cache == true
    end

    # Public: Reads all keys for a given feature.
    def get(feature)
      if using_local_cache?
        local_cache.fetch(feature.name) {
          local_cache[feature.name] = super
        }
      else
        super
      end
    end

    # Public: Enable feature gate for thing.
    def enable(feature, gate, thing)
      result = super

      if using_local_cache?
        local_cache.delete(feature.name)
      end

      result
    end

    # Public: Disable feature gate for thing.
    def disable(feature, gate, thing)
      result = super

      if using_local_cache?
        local_cache.delete(feature.name)
      end

      result
    end

    # Public: Returns all the features that the adapter knows of.
    def features
      super
    end

    # Internal: Adds a known feature to the set of features.
    def add(feature)
      super
    end
  end
end
