# Note: You should never need to require this file directly if you are using
# ActiveSupport::Notifications. Instead, you should require the metriks file
# that lives in the same directory as this file. The benefit is that it
# subscribes to the correct events and does everything for your.
require 'metriks'

module Flipper
  module Instrumentation
    class MetriksSubscriber
      # Public: Use this as the subscribed block.
      def self.call(name, start, ending, transaction_id, payload)
        new(name, start, ending, transaction_id, payload).update
      end

      # Private: Initializes a new event processing instance.
      def initialize(name, start, ending, transaction_id, payload)
        @name = name
        @start = start
        @ending = ending
        @payload = payload
        @duration = ending - start
        @transaction_id = transaction_id
      end

      def update
        operation_type = @name.split('.').first
        method_name = "update_#{operation_type}_metrics"

        if respond_to?(method_name)
          send(method_name)
        else
          puts "Could not update #{operation_type} metrics as MetriksSubscriber did not respond to `#{method_name}`"
        end
      end

      def update_feature_operation_metrics
        feature_name = @payload[:feature_name]
        gate_name = @payload[:gate_name]
        operation = strip_trailing_question_mark(@payload[:operation])
        result = @payload[:result]
        thing = @payload[:thing]

        Metriks.timer("flipper.feature_operation.#{operation}").update(@duration)

        if @payload[:operation] == :enabled?
          metric_name = if result
            "flipper.feature.#{feature_name}.enabled"
          else
            "flipper.feature.#{feature_name}.disabled"
          end

          Metriks.meter(metric_name).mark
        end
      end

      def update_adapter_operation_metrics
        adapter_name = @payload[:adapter_name]
        operation = @payload[:operation]
        result = @payload[:result]
        value = @payload[:value]
        key = @payload[:key]

        Metriks.timer("flipper.adapter.#{adapter_name}.#{operation}").update(@duration)
      end

      def update_gate_operation_metrics
        feature_name = @payload[:feature_name]
        gate_name = @payload[:gate_name]
        operation = strip_trailing_question_mark(@payload[:operation])
        result = @payload[:result]
        thing = @payload[:thing]

        Metriks.timer("flipper.gate_operation.#{gate_name}.#{operation}").update(@duration)
        Metriks.timer("flipper.feature.#{feature_name}.gate_operation.#{gate_name}.#{operation}").update(@duration)

        if @payload[:operation] == :open?
          metric_name = if result
            "flipper.feature.#{feature_name}.gate.#{gate_name}.open"
          else
            "flipper.feature.#{feature_name}.gate.#{gate_name}.closed"
          end

          Metriks.meter(metric_name).mark
        end
      end

      def strip_trailing_question_mark(operation)
        operation.to_s.gsub(/\?$/, '')
      end
    end
  end
end
