module Flipper
  class Gate
    def initialize(feature)
      @feature = feature
    end

    def feature_prefix
      @feature.name
    end

    def key
      "#{feature_prefix}.#{type_key}"
    end

    def toggle_class
      Toggles::Value
    end

    def toggle
      @toggle ||= toggle_class.new(@feature.adapter, key)
    end

    def protects?(thing)
      false
    end

    def match?(actor)
      false
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
