require 'forwardable'
require 'flipper/key'
require 'flipper/instrumentors/noop'

module Flipper
  class Gate
    extend Forwardable

    # Private
    attr_reader :feature

    # Private: What is used to instrument all the things.
    attr_reader :instrumentor

    def_delegator :@feature, :adapter

    def initialize(feature, options = {})
      @feature = feature
      @instrumentor = options.fetch(:instrumentor, Flipper::Instrumentors::Noop)
    end

    def name
      raise 'Not implemented'
    end

    def type_key
      raise 'Not implemented'
    end

    def key
      @key ||= Key.new(@feature.name, type_key)
    end

    def toggle_class
      Toggles::Value
    end

    def toggle
      @toggle ||= toggle_class.new(self)
    end

    def open?(thing)
      false
    end

    def protects?(thing)
      false
    end

    def enable(thing)
      toggle.enable(thing)
    end

    def disable(thing)
      toggle.disable(thing)
    end

    def inspect
      attributes = [
        "feature=#{feature.name.inspect}",
        "adapter=#{adapter.name.inspect}",
        "toggle_class=#{toggle_class.inspect}",
        "toggle_value=#{toggle.value.inspect}",
        "key=#{key.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    private

    def instrument(action, thing)
      name = instrument_name(action)
      payload = {
        :thing => thing,
      }
      @instrumentor.instrument(name, payload) { yield }
    end

    def instrument_name(action)
      "#{action}.#{name}.gate.flipper"
    end
  end
end

require 'flipper/gates/actor'
require 'flipper/gates/boolean'
require 'flipper/gates/group'
require 'flipper/gates/percentage_of_actors'
require 'flipper/gates/percentage_of_random'
