require 'flipper/adapter'
require 'flipper/errors'
require 'flipper/type'
require 'flipper/toggle'
require 'flipper/gate'

module Flipper
  class Feature
    attr_reader :name
    attr_reader :adapter

    def initialize(name, adapter)
      @name = name
      @adapter = Adapter.wrap(adapter)
    end

    def enable(thing = Types::Boolean.new)
      gate_for(thing).enable(thing)
    end

    def disable(thing = Types::Boolean.new)
      gate_for(thing).disable(thing)
    end

    def enabled?(actor = nil)
      !! catch(:short_circuit) { gates.detect { |gate| gate.open?(actor) } }
    end

    def disabled?(actor = nil)
      !enabled?(actor)
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

    private

    def find_gate(thing)
      gates.detect { |gate| gate.protects?(thing) }
    end
  end
end
