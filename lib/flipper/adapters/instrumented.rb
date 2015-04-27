require 'flipper/adapters/decorator'
require 'flipper/instrumenters/noop'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter and instruments all adapter
    # operations. Used by flipper dsl to provide instrumentatin for flipper.
    class Instrumented < Decorator
      # Private: The name of instrumentation events.
      InstrumentationName = "adapter_operation.#{InstrumentationNamespace}"

      # Private: What is used to instrument all the things.
      attr_reader :instrumenter

      # Internal: Initializes a new adapter instance.
      #
      # adapter - Vanilla adapter instance to wrap.
      #
      # options - The Hash of options.
      #           :instrumenter - What to use to instrument all the things.
      #
      def initialize(adapter, options = {})
        super(adapter)
        @name = :instrumented
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
      end

      # Public
      def features
        payload = {
          :operation => :features,
          :adapter_name => name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public
      def add(feature)
        payload = {
          :operation => :add,
          :adapter_name => name,
          :feature_name => feature.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public
      def remove(feature)
        payload = {
          :operation => :remove,
          :adapter_name => name,
          :feature_name => feature.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public
      def clear(feature)
        payload = {
          :operation => :clear,
          :adapter_name => name,
          :feature_name => feature.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public
      def get(feature)
        payload = {
          :operation => :get,
          :adapter_name => name,
          :feature_name => feature.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public
      def enable(feature, gate, thing)
        payload = {
          :operation => :enable,
          :adapter_name => name,
          :feature_name => feature.name,
          :gate_name => gate.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end

      # Public
      def disable(feature, gate, thing)
        payload = {
          :operation => :disable,
          :adapter_name => name,
          :feature_name => feature.name,
          :gate_name => gate.name,
        }

        @instrumenter.instrument(InstrumentationName, payload) { |payload|
          payload[:result] = super
        }
      end
    end
  end
end
