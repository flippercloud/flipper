require 'flipper/adapter'
require 'flipper/errors'
require 'flipper/type'
require 'flipper/toggle'
require 'flipper/gate'
require 'flipper/instrumentors/noop'

module Flipper
  class Feature
    # Private
    attr_reader :name

    # Private
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumentor

    def initialize(name, adapter, options = {})
      @name = name
      @instrumentor = options.fetch(:instrumentor, Flipper::Instrumentors::Noop)
      @adapter = Adapter.wrap(adapter, :instrumentor => @instrumentor)
    end

    def enable(thing = Types::Boolean.new)
      gate = gate_for(thing)
      instrument(:enable, thing, gate) { gate.enable(thing) }
    end

    def disable(thing = Types::Boolean.new)
      gate = gate_for(thing)
      instrument(:disable, thing, gate) { gate.disable(thing) }
    end

    def enabled?(thing = nil)
      instrument(:enabled, thing) { any_gates_open?(thing) }
    end

    def disabled?(thing = nil)
      instrument(:disabled, thing) { !any_gates_open?(thing) }
    end

    # Internal: Gates to check to see if feature is enabled/disabled
    #
    # Returns an array of gates
    def gates
      @gates ||= [
        Gates::Boolean.new(self),
        Gates::Group.new(self),
        Gates::Actor.new(self),
        Gates::PercentageOfActors.new(self),
        Gates::PercentageOfRandom.new(self),
      ]
    end

    # Internal: Returns gate that protects thing
    #
    # thing - The object for which you would like to find a gate
    #
    # Raises Flipper::GateNotFound if no gate found for thing
    def gate_for(thing)
      find_gate(thing) || raise(GateNotFound.new(thing))
    end

    def inspect
      attributes = [
        "name=#{name.inspect}",
        "adapter=#{adapter.name.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    private

    def any_gates_open?(thing)
      !!catch(:short_circuit) { gates.detect { |gate| gate.open?(thing) } }
    end

    def instrument(action, thing, gate = nil)
      instrument_name = instrumentation_name(action)
      payload = {
        :feature_name => name,
        :thing => thing,
      }
      payload[:gate] = gate if gate
      @instrumentor.instrument(instrument_name, payload) { yield }
    end

    def instrumentation_name(action)
      "#{action}.#{name}.feature.flipper"
    end

    def find_gate(thing)
      gates.detect { |gate| gate.protects?(thing) }
    end
  end
end
