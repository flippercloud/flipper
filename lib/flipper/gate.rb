require 'forwardable'
require 'flipper/instrumenters/noop'

module Flipper
  class Gate
    extend Forwardable

    # Private: The name of instrumentation events.
    InstrumentationName = "gate_operation.#{InstrumentationNamespace}"

    # Private: What is used to instrument all the things.
    attr_reader :instrumenter

    # Public
    def initialize(options = {})
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
    end

    # Public: The name of the gate. Implemented in subclass.
    def name
      raise 'Not implemented'
    end

    # Private: Name converted to value safe for adapter. Implemented in subclass.
    def key
      raise 'Not implemented'
    end

    def data_type
      raise 'Not implemented'
    end

    def enable(thing)
      raise 'Not implemented'
    end

    def disable(thing)
      raise 'Not implemented'
    end

    def enabled?(value)
      raise 'Not implemented'
    end

    def description(value)
      raise 'Not implemented'
    end

    # Internal: Check if a gate is open for a thing. Implemented in subclass.
    #
    # Returns true if gate open for thing, false if not.
    def open?(thing, value, options = {})
      false
    end

    # Internal: Check if a gate is protects a thing. Implemented in subclass.
    #
    # Returns true if gate protects thing, false if not.
    def protects?(thing)
      false
    end

    # Internal: Allows gate to wrap thing using one of the supported flipper
    # types so adapters always get something that responds to value.
    def wrap(thing)
      thing
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = []
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    # Private
    def instrument(operation, thing)
      payload = {
        :thing => thing,
        :operation => operation,
        :gate_name => name,
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
