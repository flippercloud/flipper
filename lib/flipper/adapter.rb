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

    # Private: The name of the key that stores the set of known features.
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
    attr_reader :name

    # Private: What is used to store the local cache.
    attr_reader :local_cache

    # Private: What is used to instrument all the things.
    attr_reader :instrumenter

    # Internal: Initializes a new adapter instance.
    #
    # adapter - Vanilla adapter instance to wrap. Just needs to respond to
    #           read, write, delete, set_members, set_add, and set_delete.
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

    # Public: Reads a key.
    def read(key)
      if using_local_cache?
        local_cache.fetch(key.to_s) {
          local_cache[key.to_s] = perform_read(key)
        }
      else
        perform_read(key)
      end
    end

    # Public: Set a key to a value.
    def write(key, value)
      value = value.to_s
      result = perform_write(key, value)

      if using_local_cache?
        local_cache.delete(key.to_s)
      end

      result
    end

    # Public: Deletes a key.
    def delete(key)
      result = perform_delete(key)

      if using_local_cache?
        local_cache.delete(key.to_s)
      end

      result
    end

    # Public: Returns the members of a set.
    def set_members(key)
      if using_local_cache?
        local_cache.fetch(key.to_s) {
          local_cache[key.to_s] = perform_set_members(key)
        }
      else
        perform_set_members(key)
      end
    end

    # Public: Adds a value to a set.
    def set_add(key, value)
      value = value.to_s
      result = perform_set_add(key, value)

      if using_local_cache?
        local_cache.delete(key.to_s)
      end

      result
    end

    # Public: Deletes a value from a set.
    def set_delete(key, value)
      value = value.to_s
      result = perform_set_delete(key, value)

      if using_local_cache?
        local_cache.delete(key.to_s)
      end

      result
    end

    # Public: Determines equality for an adapter instance when compared to
    # another object.
    def eql?(other)
      self.class.eql?(other.class) && adapter == other.adapter
    end
    alias_method :==, :eql?

    # Public: Returns all the features that the adapter knows of.
    def features
      set_members(FeaturesKey)
    end

    # Internal: Adds a known feature to the set of features.
    def feature_add(name)
      set_add(FeaturesKey, name.to_s)
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "use_local_cache=#{@use_local_cache.inspect}"
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
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

    # Private
    def perform_read(key)
      payload = {
        :key => key,
        :operation => :read,
        :adapter_name => @name,
      }

      instrument_operation :read, payload, key
    end

    def perform_write(key, value)
      payload = {
        :key => key,
        :value => value,
        :operation => :write,
        :adapter_name => @name,
      }

      instrument_operation :write, payload, key, value
    end

    # Private
    def perform_delete(key)
      payload = {
        :key => key,
        :operation => :delete,
        :adapter_name => @name,
      }

      instrument_operation :delete, payload, key
    end

    def perform_set_members(key)
      payload = {
        :key => key,
        :operation => :set_members,
        :adapter_name => @name,
      }

      instrument_operation :set_members, payload, key
    end

    def perform_set_add(key, value)
      payload = {
        :key => key,
        :value => value,
        :operation => :set_add,
        :adapter_name => @name,
      }

      instrument_operation :set_add, payload, key, value
    end

    def perform_set_delete(key, value)
      payload = {
        :key => key,
        :value => value,
        :operation => :set_delete,
        :adapter_name => @name,
      }

      instrument_operation :set_delete, payload, key, value
    end

    # Private: Instruments operation with payload.
    def instrument_operation(operation, payload = {}, *args)
      @instrumenter.instrument(InstrumentationName, payload) { |payload|
        payload[:result] = @adapter.send(operation, *args)
      }
    end
  end
end
