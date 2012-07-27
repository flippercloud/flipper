module Flipper
  class Gate
    def initialize(feature)
      @feature = feature
    end

    def protects?(thing)
      false
    end

    def match?(actor)
      false
    end

    def toggle
      raise 'Not implemented'
    end

    def enable(thing)
      toggle.enable(thing)
    end

    def disable(thing)
      toggle.disable(thing)
    end
  end
end

require 'flipper/gates/actor'
require 'flipper/gates/boolean'
require 'flipper/gates/group'
require 'flipper/gates/percentage_of_actors'
require 'flipper/gates/percentage_of_time'
