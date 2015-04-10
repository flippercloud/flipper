require 'flipper/errors'
require 'flipper/type'
require 'flipper/gate'
require 'flipper/gate_values'
require 'flipper/instrumenters/noop'

module Flipper
  class Feature
    # Private: The name of feature instrumentation events.
    InstrumentationName = "feature_operation.#{InstrumentationNamespace}"

    # Private: The name of gate instrumentation events.
    GateInstrumentationName = "gate_operation.#{InstrumentationNamespace}"

    # Public: The name of the feature.
    attr_reader :name

    # Public: Name converted to value safe for adapter.
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
    # Returns the result of Adapter#enable.
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
    # Returns the result of Adapter#disable.
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

        open_gate = gates.detect { |gate|
          instrument_gate(gate, :open?, thing) { |gate_payload|
            gate.open?(thing, values[gate.key], feature_name: @name)
          }
        }

        if open_gate.nil?
          false
        else
          payload[:gate_name] = open_gate.name
          true
        end
      }
    end

    # Public: Enables a feature for an actor.
    #
    # actor - a Flipper::Types::Actor instance or an object that responds
    #         to flipper_id.
    #
    # Returns result of enable.
    def enable_actor(actor)
      enable Types::Actor.wrap(actor)
    end

    # Public: Enables a feature for a group.
    #
    # group - a Flipper::Types::Group instance or a String or Symbol name of a
    #         registered group.
    #
    # Returns result of enable.
    def enable_group(group)
      enable Flipper::Types::Group.wrap(group)
    end

    # Public: Enables a feature a percentage of time.
    #
    # percentage - a Flipper::Types::PercentageOfTime instance or an object that
    #              responds to to_i.
    #
    # Returns result of enable.
    def enable_percentage_of_time(percentage)
      enable Types::PercentageOfTime.wrap(percentage)
    end

    # Public: Enables a feature for a percentage of actors.
    #
    # percentage - a Flipper::Types::PercentageOfTime instance or an object that
    #              responds to to_i.
    #
    # Returns result of enable.
    def enable_percentage_of_actors(percentage)
      enable Types::PercentageOfActors.wrap(percentage)
    end

    # Public: Disables a feature for an actor.
    #
    # actor - a Flipper::Types::Actor instance or an object that responds
    #         to flipper_id.
    #
    # Returns result of disable.
    def disable_actor(actor)
      disable Types::Actor.wrap(actor)
    end

    # Public: Disables a feature for a group.
    #
    # group - a Flipper::Types::Group instance or a String or Symbol name of a
    #         registered group.
    #
    # Returns result of disable.
    def disable_group(group)
      disable Flipper::Types::Group.wrap(group)
    end

    # Public: Disables a feature a percentage of time.
    #
    # percentage - a Flipper::Types::PercentageOfTime instance or an object that
    #              responds to to_i.
    #
    # Returns result of disable.
    def disable_percentage_of_time
      disable Types::PercentageOfTime.new(0)
    end

    # Public: Disables a feature for a percentage of actors.
    #
    # percentage - a Flipper::Types::PercentageOfTime instance or an object that
    #              responds to to_i.
    #
    # Returns result of disable.
    def disable_percentage_of_actors
      disable Types::PercentageOfActors.new(0)
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

    # Public: Is the feature fully enabled.
    def on?
      state == :on
    end

    # Public: Is the feature fully disabled.
    def off?
      state == :off
    end

    # Public: Is the feature conditionally enabled for a given actor, group,
    # percentage of actors or percentage of the time.
    def conditional?
      state == :conditional
    end

    # Public: Human readable description of the enabled-ness of the feature.
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

    # Public: Get groups enabled for this feature.
    #
    # Returns Set of Flipper::Group instances.
    def enabled_groups
      groups_value.map { |name| Flipper.group(name) }.to_set
    end
    alias_method :groups, :enabled_groups

    # Public: Get groups not enabled for this feature.
    #
    # Returns Set of Flipper::Group instances.
    def disabled_groups
      Flipper.groups - enabled_groups
    end

    # Public: Get the adapter value for the groups gate.
    #
    # Returns Set of String group names.
    def groups_value
      gate_values.groups
    end

    # Public: Get the adapter value for the actors gate.
    #
    # Returns Set of String flipper_id's.
    def actors_value
      gate_values.actors
    end

    # Public: Get the adapter value for the boolean gate.
    #
    # Returns true or false.
    def boolean_value
      gate_values.boolean
    end

    # Public: Get the adapter value for the percentage of actors gate.
    #
    # Returns Integer greater than or equal to 0 and less than or equal to 100.
    def percentage_of_actors_value
      gate_values.percentage_of_actors
    end

    # Public: Get the adapter value for the percentage of time gate.
    #
    # Returns Integer greater than or equal to 0 and less than or equal to 100.
    def percentage_of_time_value
      gate_values.percentage_of_time
    end

    # Public: Returns the string representation of the feature.
    def to_s
      name.to_s
    end

    # Public: Identifier to be used in the url (a rails-ism).
    def to_param
      to_s
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

    # Public: Get all the gates used to determine enabled/disabled for the feature.
    #
    # Returns an array of gates
    def gates
      @gates ||= [
        Gates::Boolean.new,
        Gates::Group.new,
        Gates::Actor.new,
        Gates::PercentageOfActors.new,
        Gates::PercentageOfTime.new,
      ]
    end

    # Public: Find a gate by name.
    #
    # Returns a Flipper::Gate if found, nil if not.
    def gate(name)
      gates.detect { |gate| gate.name == name.to_sym }
    end

    # Public: Find the gate that protects a thing.
    #
    # thing - The object for which you would like to find a gate
    #
    # Returns a Flipper::Gate.
    # Raises Flipper::GateNotFound if no gate found for thing
    def gate_for(thing)
      gates.detect { |gate| gate.protects?(thing) } ||
        raise(GateNotFound.new(thing))
    end

    private

    # Private: Get the boolean gate.
    def boolean_gate
      @boolean_gate ||= gate(:boolean)
    end

    # Private: Get all gates except the boolean gate.
    def non_boolean_gates
      @non_boolean_gates ||= gates - [boolean_gate]
    end

    # Private: Get all non boolean gates that are enabled in some way.
    def conditional_gates(gate_values)
      non_boolean_gates.select { |gate|
        value = gate_values[gate.key]
        gate.enabled?(value)
      }
    end

    # Private: Instrument a feature operation.
    def instrument(operation, thing)
      payload = {
        :feature_name => name,
        :operation => operation,
        :thing => thing,
      }

      @instrumenter.instrument(InstrumentationName, payload) { |payload|
        payload[:result] = yield(payload) if block_given?
      }
    end

    # Private: Intrument a gate operation.
    def instrument_gate(gate, operation, thing)
      payload = {
        :feature_name => @name,
        :gate_name => gate.name,
        :operation => operation,
        :thing => thing,
      }

      @instrumenter.instrument(GateInstrumentationName, payload) { |payload|
        payload[:result] = yield(payload) if block_given?
      }
    end
  end
end
