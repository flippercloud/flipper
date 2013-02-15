require 'flipper/instrumenters/noop'

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
    # Private: The name of instrumentation events.
    InstrumentationName = "adapter_operation.#{InstrumentationNamespace}"

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
    attr_reader :name

    # Private: What is used to store the local cache.
    attr_reader :local_cache

    # Private: What is used to instrument all the things.
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
    #           :instrumenter - What to use to instrument all the things.
    #
    def initialize(adapter, options = {})
      @adapter = adapter
      @name = adapter.class.name.split('::').last.downcase.to_sym
      @local_cache = options[:local_cache] || {}
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
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
          local_cache[feature.name] = perform_get(feature)
        }
      else
        perform_get(feature)
      end
    end

    # Public: Enable feature gate for thing.
    def enable(feature, gate, thing)
      result = perform_enable(feature, gate, thing)

      if using_local_cache?
        local_cache.delete(feature.name)
      end

      result
    end

    # Public: Disable feature gate for thing.
    def disable(feature, gate, thing)
      result = perform_disable(feature, gate, thing)

      if using_local_cache?
        local_cache.delete(feature.name)
      end

      result
    end

    # Public: Returns all the features that the adapter knows of.
    def features
      perform_features
    end

    # Internal: Adds a known feature to the set of features.
    def add(feature)
      perform_add(feature)
    end

    # Public: Determines equality for an adapter instance when compared to
    # another object.
    def eql?(other)
      self.class.eql?(other.class) && adapter == other.adapter
    end
    alias_method :==, :eql?

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "use_local_cache=#{@use_local_cache.inspect}"
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    def perform_enable(feature, gate, thing)
      payload = {
        :operation => :enable,
        :adapter_name => @name,
        :feature_name => feature.name,
        :gate_name => gate.name,
      }

      instrument_operation :enable, payload, feature, gate, thing
    end

    def perform_disable(feature, gate, thing)
      payload = {
        :operation => :disable,
        :adapter_name => @name,
        :feature_name => feature.name,
        :gate_name => gate.name,
      }

      instrument_operation :disable, payload, feature, gate, thing
    end

    # Private: Performs actual get with instrumentation.
    def perform_get(feature)
      payload = {
        :operation => :get,
        :adapter_name => @name,
        :feature_name => feature.name,
      }

      instrument_operation :get, payload, feature
    end

    def perform_features
      payload = {
        :operation => :features,
        :adapter_name => @name,
      }

      instrument_operation :features, payload
    end

    def perform_add(feature)
      payload = {
        :operation => :add,
        :adapter_name => @name,
        :feature_name => feature.name,
      }

      instrument_operation :add, payload, feature
    end

    # Private: Instruments operation with payload.
    def instrument_operation(operation, payload = {}, *args)
      @instrumenter.instrument(InstrumentationName, payload) { |payload|
        payload[:result] = @adapter.send(operation, *args)
      }
    end
  end
end
