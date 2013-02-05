require 'forwardable'
require 'flipper/key'
require 'flipper/instrumenters/noop'

module Flipper
  class Gate
    extend Forwardable

    # Private: The name of instrumentation events.
    InstrumentationName = "gate_operation.#{InstrumentationNamespace}"

    # Private
    attr_reader :feature

    # Private: What is used to instrument all the things.
    attr_reader :instrumenter

    def_delegator :@feature, :adapter

    def initialize(feature, options = {})
      @feature = feature
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
    end

    # Public: The name of the gate. Implemented in subclass.
    def name
      raise 'Not implemented'
    end

    # Private: The piece of the adapter key that is unique to the gate class.
    # Implemented in subclass.
    def key
      raise 'Not implemented'
    end

    # Internal: The key where details about this gate can be retrieved from the
    # adapter.
    def adapter_key
      @key ||= Key.new(@feature.name, key)
    end

    # Internal: The toggle class to use for this gate.
    def toggle_class
      Toggles::Value
    end

    # Internal: The toggle to use to enable/disable this gate.
    def toggle
      @toggle ||= toggle_class.new(self)
    end

    # Internal: Check if a gate is open for a thing. Implemented in subclass.
    #
    # Returns true if gate open for thing, false if not.
    def open?(thing)
      false
    end

    # Internal: Check if a gate is protects a thing. Implemented in subclass.
    #
    # Returns true if gate protects thing, false if not.
    def protects?(thing)
      false
    end

    # Internal: Enable this gate for a thing.
    #
    # Returns the result of Flipper::Toggle#enable.
    def enable(thing)
      toggle.enable(thing)
    end

    # Internal: Disable this gate for a thing.
    #
    # Returns the result of Flipper::Toggle#disable.
    def disable(thing)
      toggle.disable(thing)
    end

    def enabled?
      toggle.enabled?
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "feature=#{feature.name.inspect}",
        "description=#{description.inspect}",
        "adapter=#{adapter.name.inspect}",
        "adapter_key=#{adapter_key.inspect}",
        "toggle_class=#{toggle_class.inspect}",
        "toggle_value=#{toggle.value.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    private

    def instrument(operation, thing)
      payload = {
        :thing => thing,
        :operation => operation,
        :gate_name => name,
        :feature_name => @feature.name,
      }

      @instrumenter.instrument(InstrumentationName, payload) {
        payload[:result] = yield(payload) if block_given?
      }
    end
  end
end

require 'flipper/gates/actor'
require 'flipper/gates/boolean'
require 'flipper/gates/group'
require 'flipper/gates/percentage_of_actors'
require 'flipper/gates/percentage_of_random'
