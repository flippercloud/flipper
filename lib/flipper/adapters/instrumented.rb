require 'delegate'

module Flipper
  module Adapters
    # Internal: Adapter that wraps another adapter and instruments all adapter
    # operations.
    class Instrumented
      include ::Flipper::Adapter

      # Private: The name of instrumentation events.
      InstrumentationName = "adapter_operation.#{InstrumentationNamespace}".freeze

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
        @adapter = adapter
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
      end

      # Public
      def features
        default_payload = {
          operation: :features,
          adapter_name: @adapter.name,
        }

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
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

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
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

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
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

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
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

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.get(feature)
        end
      end

      def get_multi(features)
        default_payload = {
          operation: :get_multi,
          adapter_name: @adapter.name,
          feature_names: features.map(&:name),
        }

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.get_multi(features)
        end
      end

      def get_all
        default_payload = {
          operation: :get_all,
          adapter_name: @adapter.name,
        }

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
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

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
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

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.disable(feature, gate, thing)
        end
      end

      def import(source)
        default_payload = {
          operation: :import,
          adapter_name: @adapter.name,
        }

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.import(source)
        end
      end

      def export(format: :json, version: 1)
        default_payload = {
          operation: :export,
          adapter_name: @adapter.name,
          format: format,
          version: version,
        }

        @instrumenter.instrument(InstrumentationName, default_payload) do |payload|
          payload[:result] = @adapter.export(format: format, version: version)
        end
      end
    end
  end
end
