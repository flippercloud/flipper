require 'forwardable'

module Flipper
  # Internal: Used by gate to toggle values (true/false, add/delete from set, etc.).
  # Named poorly maybe, but haven't come up with a better name yet.
  class Toggle
    extend Forwardable

    attr_reader :gate

    def_delegators :@gate, :adapter_key, :feature, :adapter

    def initialize(gate)
      @gate = gate
    end

    # Internal: Enables thing for gate and adds feature to known features.
    #
    # Returns Boolean (currently always true).
    def enable(thing)
      add_feature_to_set
    end

    # Internal: Disables thing for gate and adds feature to known features.
    #
    # Returns Boolean (currently always true).
    def disable(thing)
      add_feature_to_set
    end

    def value
      raise 'Not implemented'
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "gate=#{gate.inspect}",
        "value=#{value}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    private

    def add_feature_to_set
      adapter.feature_add adapter_key.feature_name
    end
  end
end

require 'flipper/toggles/boolean'
require 'flipper/toggles/set'
require 'flipper/toggles/value'
