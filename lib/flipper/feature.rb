require 'flipper/errors'
require 'flipper/boolean'
require 'flipper/group'
require 'flipper/percentage_of_actors'
require 'flipper/toggle'
require 'flipper/gate'

module Flipper
  class Feature
    attr_reader :name
    attr_reader :adapter

    def initialize(name, adapter)
      @name = name
      @adapter = adapter
    end

    def enable(thing = Boolean.new)
      gate_for(thing).enable(thing)
    end

    def disable(thing = Boolean.new)
      gate_for(thing).disable(thing)
    end

    def enabled?(actor = nil)
      !! catch(:short_circuit) { gates.detect { |gate| gate.match?(actor) } }
    end

    def disabled?(actor = nil)
      !enabled?(actor)
    end

    private

    def gate_for(thing)
      gates.detect { |gate| gate.protects?(thing) } ||
        raise(GateNotFound.new(thing))
    end

    def gates
      @gates ||= [
        Gates::Boolean.new(self),
        Gates::Group.new(self),
        Gates::Actor.new(self),
        Gates::PercentageOfActors.new(self),
      ]
    end
  end
end
