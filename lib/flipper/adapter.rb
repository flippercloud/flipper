require 'flipper/noop_instrumentor'

module Flipper
  # Internal: Adapter wrapper that wraps vanilla adapter instances. Adds things
  # like local caching and convenience methods for adding/reading features from
  # the adapter.
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
  class Adapter
    FeaturesKey = 'features'

    # Internal: Wraps vanilla adapter instance for use internally in flipper.
    #
    # object - Either an instance of Flipper::Adapter or a vanilla adapter instance
    #
    # Examples
    #
    #   adapter = Flipper::Adapters::Memory.new
    #   instance = Flipper::Adapter.new(adapter)
    #
    #   Flipper::Adapter.wrap(instance)
    #   # => Flipper::Adapter instance
    #
    #   Flipper::Adapter.wrap(adapter)
    #   # => Flipper::Adapter instance
    #
    # Returns Flipper::Adapter instance
    def self.wrap(object, options = {})
      if object.is_a?(Flipper::Adapter)
        object
      else
        new(object, options)
      end
    end

    # Private: What adapter is being wrapped and will ultimately be used.
    attr_reader :adapter

    # Private: The name of the adapter. Based on the class name.
    attr_reader :adapter_name

    # Private: What is used to store the local cache.
    attr_reader :local_cache

    # Private: What is used to instrument all the things.
    attr_reader :instrumentor

    # Internal: Initializes a new instance
    #
    # adapter - Vanilla adapter instance to wrap. Just needs to respond to
    #           read, write, delete, set_members, set_add, and set_delete.
    #
    # options - The Hash of options.
    #           :local_cache - Where to store the local cache data (default: {}).
    #                          Must respond to fetch(key, block), delete(key)
    #                          and clear.
    #           :instrumentor - What to use to instrument all the things.
    #
    def initialize(adapter, options = {})
      @adapter = adapter
      @adapter_name = adapter.class.name.split('::').last.downcase
      @local_cache = options[:local_cache] || {}
      @instrumentor = options.fetch(:instrumentor, Flipper::NoopInstrumentor)
    end

    def use_local_cache=(value)
      local_cache.clear
      @use_local_cache = value
    end

    def using_local_cache?
      @use_local_cache == true
    end

    def read(key)
      perform_read(:read, key)
    end

    def write(key, value)
      perform_update(:write, key, value)
    end

    def delete(key)
      perform_delete(:delete, key)
    end

    def set_members(key)
      perform_read(:set_members, key)
    end

    def set_add(key, value)
      perform_update(:set_add, key, value)
    end

    def set_delete(key, value)
      perform_update(:set_delete, key, value)
    end

    def eql?(other)
      self.class.eql?(other.class) && adapter == other.adapter
    end
    alias_method :==, :eql?

    def features
      set_members(FeaturesKey)
    end

    def feature_add(name)
      set_add(FeaturesKey, name.to_s)
    end

    private

    def perform_read(operation, key)
      if using_local_cache?
        local_cache.fetch(key.to_s) {
          local_cache[key.to_s] = @adapter.send(operation, key)
        }
      else
        name = instrumentation_name(operation)
        payload = {:key => key}

        @instrumentor.instrument(name, payload) {
          @adapter.send(operation, key)
        }
      end
    end

    def perform_update(operation, key, value)
      name = instrumentation_name(operation)
      payload = {:key => key, :value => value}

      result = @instrumentor.instrument(name, payload) {
        @adapter.send(operation, key, value)
      }

      if using_local_cache?
        local_cache.delete(key.to_s)
      end

      result
    end

    def perform_delete(operation, key)
      name = instrumentation_name(operation)
      payload = {:key => key}

      result = @instrumentor.instrument(name, payload) {
        @adapter.send(operation, key)
      }

      if using_local_cache?
        local_cache.delete(key.to_s)
      end

      result
    end

    def instrumentation_name(operation)
      "#{operation}.#{adapter_name}.adapter.flipper"
    end
  end
end
