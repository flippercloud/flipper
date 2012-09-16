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
      add_feature_to_set
    end

    def disable(thing)
      add_feature_to_set
    end

    def value
      raise 'Not implemented'
    end

    private

    def add_feature_to_set
      adapter.feature_add key.prefix
    end
  end
end

require 'flipper/toggles/boolean'
require 'flipper/toggles/set'
require 'flipper/toggles/value'
