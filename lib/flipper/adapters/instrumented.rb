require 'delegate'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter and instruments all adapter
    # operations.
    class Instrumented < SimpleDelegator
      include ::Flipper::Adapter
      include DeprecatedInstrumenter

      # Private: The name of instrumentation events.
      InstrumentationName = "adapter_operation.#{InstrumentationNamespace}".freeze

      # Public: The name of the adapter.
      attr_reader :name

      # Internal: Initializes a new adapter instance.
      #
      # adapter - Vanilla adapter instance to wrap.
      #
      def initialize(adapter, options = {})
        super(adapter)
        deprecated_instrumenter_option options
        @adapter = adapter
        @name = :instrumented
      end

      # Public
      def features
        default_payload = {
          operation: :features,
          adapter_name: @adapter.name,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.features
        end
      end

      # Public
      def add(feature)
        default_payload = {
          operation: :add,
          adapter_name: @adapter.name,
          feature_name: feature.name,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.add(feature)
        end
      end

      # Public
      def remove(feature)
        default_payload = {
          operation: :remove,
          adapter_name: @adapter.name,
          feature_name: feature.name,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.remove(feature)
        end
      end

      # Public
      def clear(feature)
        default_payload = {
          operation: :clear,
          adapter_name: @adapter.name,
          feature_name: feature.name,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.clear(feature)
        end
      end

      # Public
      def get(feature)
        default_payload = {
          operation: :get,
          adapter_name: @adapter.name,
          feature_name: feature.name,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.get(feature)
        end
      end

      def get_multi(features)
        default_payload = {
          operation: :get_multi,
          adapter_name: @adapter.name,
          feature_names: features.map(&:name),
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.get_multi(features)
        end
      end

      def get_all
        default_payload = {
          operation: :get_all,
          adapter_name: @adapter.name,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.get_all
        end
      end

      # Public
      def enable(feature, gate, thing)
        default_payload = {
          operation: :enable,
          adapter_name: @adapter.name,
          feature_name: feature.name,
          gate_name: gate.name,
          thing_value: thing.value,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.enable(feature, gate, thing)
        end
      end

      # Public
      def disable(feature, gate, thing)
        default_payload = {
          operation: :disable,
          adapter_name: @adapter.name,
          feature_name: feature.name,
          gate_name: gate.name,
          thing_value: thing.value,
        }

        Flipper.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.disable(feature, gate, thing)
        end
      end
    end
  end
end
