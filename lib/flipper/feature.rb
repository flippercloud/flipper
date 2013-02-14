require 'flipper/adapter'
require 'flipper/errors'
require 'flipper/type'
require 'flipper/gate'
require 'flipper/instrumenters/noop'

module Flipper
  class Feature
    # Private: The name of instrumentation events.
    InstrumentationName = "feature_operation.#{InstrumentationNamespace}"

    # Internal: The name of the feature.
    attr_reader :name

    # Internal: Name converted to value safe for adapter.
    attr_reader :key

    # Private: The adapter this feature should use.
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumenter

    # Internal: Initializes a new feature instance.
    #
    # name - The Symbol or String name of the feature.
    # adapter - The adapter that will be used to store details about this feature.
    #
    # options - The Hash of options.
    #           :instrumenter - What to use to instrument all the things.
    #
    def initialize(name, adapter, options = {})
      @name = name
      @key = name.to_s
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      @adapter = Adapter.wrap(adapter, :instrumenter => @instrumenter)
    end

    # Public: Enable this feature for something.
    #
    # Returns the result of Flipper::Gate#enable.
    def enable(thing = Types::Boolean.new(true))
      instrument(:enable, thing) { |payload|
        adapter.feature_add @name

        gate = gate_for(thing)
        payload[:gate_name] = gate.name

        adapter.enable self, gate, gate.wrap(thing)
      }
    end

    # Public: Disable this feature for something.
    #
    # Returns the result of Flipper::Gate#disable.
    def disable(thing = Types::Boolean.new(false))
      instrument(:disable, thing) { |payload|
        adapter.feature_add @name

        gate = gate_for(thing)
        payload[:gate_name] = gate.name

        adapter.disable self, gate, gate.wrap(thing)
      }
    end

    # Public: Check if a feature is enabled for a thing.
    #
    # Returns true if enabled, false if not.
    def enabled?(thing = nil)
      instrument(:enabled?, thing) { |payload|
        gate_values = adapter.get(self)

        gate = gates.detect { |gate|
          gate.open?(thing, gate_values[gate])
        }

        if gate.nil?
          false
        else
          payload[:gate_name] = gate.name
          true
        end
      }
    end

    # Public
    def state
      gate_values = adapter.get(self)
      boolean_value = gate_values[boolean_gate]

      if boolean_gate.enabled?(boolean_value)
        :on
      elsif conditional_gates(gate_values).any?
        :conditional
      else
        :off
      end
    end

    # Public
    def description
      gate_values = adapter.get(self)
      boolean_value = gate_values[boolean_gate]
      conditional_gates = conditional_gates(gate_values)

      if boolean_gate.enabled?(boolean_value)
        boolean_gate.description(boolean_value).capitalize
      elsif conditional_gates.any?
        fragments = conditional_gates.map { |gate|
          value = gate_values[gate]
          gate.description(value)
        }

        "Enabled for #{fragments.join(', ')}"
      else
        boolean_gate.description(boolean_value).capitalize
      end
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "state=#{state.inspect}",
        "description=#{description.inspect}",
        "adapter=#{adapter.name.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    # Internal: Gates to check to see if feature is enabled/disabled
    #
    # Returns an array of gates
    def gates
      @gates ||= [
        Gates::Boolean.new(@name, :instrumenter => @instrumenter),
        Gates::Group.new(@name, :instrumenter => @instrumenter),
        Gates::Actor.new(@name, :instrumenter => @instrumenter),
        Gates::PercentageOfActors.new(@name, :instrumenter => @instrumenter),
        Gates::PercentageOfRandom.new(@name, :instrumenter => @instrumenter),
      ]
    end

    # Internal: Finds a gate by name.
    #
    # Returns a Flipper::Gate if found, nil if not.
    def gate(name)
      gates.detect { |gate| gate.name.to_s == name.to_s }
    end

    # Internal: Find the gate that protects a thing.
    #
    # thing - The object for which you would like to find a gate
    #
    # Returns a Flipper::Gate.
    # Raises Flipper::GateNotFound if no gate found for thing
    def gate_for(thing)
      gates.detect { |gate| gate.protects?(thing) } ||
        raise(GateNotFound.new(thing))
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
    def conditional_gates(gate_values)
      @conditional_gates ||= non_boolean_gates.select { |gate|
        value = gate_values[gate]
        gate.enabled?(value)
      }
    end

    # Private
    def instrument(operation, thing)
      payload = {
        :feature_name => name,
        :operation => operation,
        :thing => thing,
      }

      @instrumenter.instrument(InstrumentationName, payload) {
        payload[:result] = yield(payload) if block_given?
      }
    end
  end
end
