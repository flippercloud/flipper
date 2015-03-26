require 'flipper/errors'
require 'flipper/type'
require 'flipper/gate'
require 'flipper/gate_values'
require 'flipper/instrumenters/noop'

module Flipper
  class Feature
    # Private: The name of instrumentation events.
    InstrumentationName = "feature_operation.#{InstrumentationNamespace}"

    # Public: The name of the feature.
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
      @adapter = adapter
    end

    # Public: Enable this feature for something.
    #
    # Returns the result of Flipper::Gate#enable.
    def enable(thing = Types::Boolean.new(true))
      instrument(:enable, thing) { |payload|
        adapter.add self

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
        adapter.add self

        gate = gate_for(thing)
        payload[:gate_name] = gate.name

        if gate.is_a?(Gates::Boolean)
          adapter.clear self
        else
          adapter.disable self, gate, gate.wrap(thing)
        end
      }
    end

    # Public: Check if a feature is enabled for a thing.
    #
    # Returns true if enabled, false if not.
    def enabled?(thing = nil)
      instrument(:enabled?, thing) { |payload|
        values = gate_values

        gate = gates.detect { |gate|
          gate.open?(thing, values[gate.key])
        }

        if gate.nil?
          false
        else
          payload[:gate_name] = gate.name
          true
        end
      }
    end

    # Public: Returns state for feature (:on, :off, or :conditional).
    def state
      values = gate_values

      if boolean_gate.enabled?(values.boolean)
        :on
      elsif conditional_gates(values).any?
        :conditional
      else
        :off
      end
    end

    # Public
    def on?
      state == :on
    end

    # Public
    def off?
      state == :off
    end

    # Public
    def conditional?
      state == :conditional
    end

    # Public
    def description
      values = gate_values
      conditional_gates = conditional_gates(values)

      if boolean_gate.enabled?(values.boolean) || !conditional_gates.any?
        boolean_gate.description(values.boolean).capitalize
      else
        fragments = conditional_gates.map { |gate|
          value = values[gate.key]
          gate.description(value)
        }

        "Enabled for #{fragments.join(', ')}"
      end
    end

    # Public: Returns the raw gate values stored by the adapter.
    def gate_values
      GateValues.new(adapter.get(self))
    end

    # Public: Returns the Set of Flipper::Types::Group instances enabled.
    def groups
      groups_value.map { |name| Flipper.group(name) }.to_set
    end

    # Public: Returns the Set of group Symbol names enabled.
    def groups_value
      gate_values.groups
    end

    # Public: Returns the Set of actor flipper ids enabled.
    def actors_value
      gate_values.actors
    end

    # Public: Returns the adapter value for the boolean gate.
    def boolean_value
      gate_values.boolean
    end

    # Public: Returns the adapter value for the percentage of actors gate.
    def percentage_of_actors_value
      gate_values.percentage_of_actors
    end

    # Public: Returns the adapter value for the percentage of random gate.
    def percentage_of_random_value
      gate_values.percentage_of_random
    end

    # Public: Returns the string representation of the feature.
    def to_s
      @to_s ||= name.to_s
    end

    # Public: Identifier to be used in the url (a rails-ism).
    def to_param
      @to_param ||= name.to_s
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
      gates.detect { |gate| gate.name == name.to_sym }
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
      @boolean_gate ||= gate(:boolean)
    end

    # Private
    def non_boolean_gates
      @non_boolean_gates ||= gates - [boolean_gate]
    end

    # Private
    def conditional_gates(gate_values)
      non_boolean_gates.select { |gate|
        value = gate_values[gate.key]
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
