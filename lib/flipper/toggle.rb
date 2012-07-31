require 'forwardable'

module Flipper
  class Toggle
    extend Forwardable

    attr_reader :gate

    def_delegators :@gate, :key, :feature, :adapter

    def initialize(gate)
      @gate = gate
    end

    def enable(thing)
      raise 'Not implemented'
    end

    def disable(thing)
      raise 'Not implemented'
    end

    def value
      raise 'Not implemented'
    end
  end
end

require 'flipper/toggles/boolean'
require 'flipper/toggles/set'
require 'flipper/toggles/value'
