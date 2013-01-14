require 'forwardable'
require 'flipper/key'
require 'flipper/instrumentors/noop'

module Flipper
  class Gate
    extend Forwardable

    # Private
    attr_reader :feature

    # Private: What is used to instrument all the things.
    attr_reader :instrumentor

    def_delegator :@feature, :adapter

    def initialize(feature, options = {})
      @feature = feature
      @instrumentor = options.fetch(:instrumentor, Flipper::Instrumentors::Noop)
    end

    # Public: The name of the gate. Implemented in subclass.
    def name
      raise 'Not implemented'
    end

    # Private: The key used in the adapter for the gate. Implemented in subclass.
    def type_key
      raise 'Not implemented'
    end

    # Internal: The key where details about this gate can be retrieved from the
    # adapter.
    def adapter_key
      @key ||= Key.new(@feature.name, type_key)
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

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "feature=#{feature.name.inspect}",
        "adapter=#{adapter.name.inspect}",
        "toggle_class=#{toggle_class.inspect}",
        "toggle_value=#{toggle.value.inspect}",
        "adapter_key=#{adapter_key.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    private

    def instrument(action, thing)
      name = instrument_name(action)
      payload = {
        :thing => thing,
      }
      @instrumentor.instrument(name, payload) { yield }
    end

    def instrument_name(action)
      "#{action}.#{name}.gate.flipper"
    end
  end
end

require 'flipper/gates/actor'
require 'flipper/gates/boolean'
require 'flipper/gates/group'
require 'flipper/gates/percentage_of_actors'
require 'flipper/gates/percentage_of_random'
