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
  end
end

require 'flipper/toggles/boolean'
require 'flipper/toggles/set'
require 'flipper/toggles/value'
