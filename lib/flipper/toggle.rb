require 'forwardable'

module Flipper
  class Toggle
    extend Forwardable

    attr_reader :gate

    def_delegators :@gate, :adapter_key, :feature, :adapter

    def initialize(gate)
      @gate = gate
    end

    def enable(thing)
      add_feature_to_set
    end

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
