require 'flipper/adapter'
require 'flipper/errors'
require 'flipper/type'
require 'flipper/toggle'
require 'flipper/gate'
require 'flipper/instrumentors/noop'

module Flipper
  class Feature
    # Internal: The name of the feature.
    attr_reader :name

    # Private: The adapter this feature should use.
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumentor

    # Internal: Initializes a new feature instance.
    #
    # name - The Symbol or String name of the feature.
    # adapter - The adapter that will be used to store details about this feature.
    #
    # options - The Hash of options.
    #           :instrumentor - What to use to instrument all the things.
    #
    def initialize(name, adapter, options = {})
      @name = name
      @instrumentor = options.fetch(:instrumentor, Flipper::Instrumentors::Noop)
      @adapter = Adapter.wrap(adapter, :instrumentor => @instrumentor)
    end

    # Public: Enable this feature for something.
    #
    # Returns the result of Flipper::Gate#enable.
    def enable(thing = Types::Boolean.new)
      gate = gate_for(thing)
      instrument(:enable, thing, gate) { gate.enable(thing) }
    end

    # Public: Disable this feature for something.
    #
    # Returns the result of Flipper::Gate#disable.
    def disable(thing = Types::Boolean.new)
      gate = gate_for(thing)
      instrument(:disable, thing, gate) { gate.disable(thing) }
    end

    # Public: Check if a feature is enabled for a thing.
    #
    # Returns true if enabled, false if not.
    def enabled?(thing = nil)
      instrument(:enabled, thing) { any_gates_open?(thing) }
    end

    # Public: Check if a feature is disabled for a thing.
    #
    # Returns true if disabled, false if not.
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

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "adapter=#{adapter.name.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    # Public
    def state
      if boolean_gate.enabled?
        :on
      elsif conditional_gates.any?
        :conditional
      else
        :off
      end
    end

    # Public
    def description
      if boolean_gate.enabled?
        boolean_gate.description
      elsif conditional_gates.any?
        fragments = conditional_gates.map(&:description)
        "Enabled for #{fragments.join(', ')}"
      else
        boolean_gate.description
      end
    end

    # Private
    def boolean_gate
      @boolean_gate ||= gates.detect { |gate| gate.name == :boolean }
    end

    # Private
    def non_boolean_gates
      @non_boolean_gates ||= gates - [boolean_gate]
    end

    # Private
    def conditional_gates
      non_boolean_gates.select { |gate| gate.enabled? }
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
