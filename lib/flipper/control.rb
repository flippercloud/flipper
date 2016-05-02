require 'flipper/instrumenters/noop'

module Flipper
  class Control
    # Private: The name of control instrumentation events.
    InstrumentationName = "control_operation.#{InstrumentationNamespace}"

    # Public: The name of the control.
    attr_reader :name

    # Public: Name converted to value safe for adapter.
    attr_reader :key

    # Private: The adapter this control should use.
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumenter

    # Internal: Initializes a new control instance.
    #
    # name - The Symbol or String name of the control.
    # adapter - The adapter that will be used to store details about this control.
    #
    # options - The Hash of options.
    #           :instrumenter - What to use to instrument all the things.
    #
    def initialize(name, adapter, options = {})
      @name = name
      @key = name.to_s
      @adapter = adapter
      @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
    end

    def value
      instrument(:value) { |payload|
        @adapter.get_control(self)
      }
    end

    def set(value)
      instrument(:set) { |payload|
        @adapter.set_control(self, value)
      }
    end

    # Public: Returns the string representation of the control.
    def to_s
      name.to_s
    end

    # Public: Identifier to be used in the url (a rails-ism).
    def to_param
      to_s
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "value=#{value.inspect}",
        "adapter=#{adapter.name.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end

    private

    # Private: Instrument a control operation.
    def instrument(operation, &block)
      @instrumenter.instrument(InstrumentationName) { |payload|
        payload[:control_name] = name
        payload[:operation] = operation
        payload[:result] = yield(payload) if block_given?
      }
    end
  end
end
