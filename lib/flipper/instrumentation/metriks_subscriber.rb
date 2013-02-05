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

        @operation = payload[:operation]
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
        # no trailing question mark in metric names
        operation = @operation.to_s.gsub(/\?$/, '')
        feature_name = @payload[:feature_name]

        Metriks.timer("flipper.feature_operation.#{operation}").update(@duration)

        if @operation == :enabled?
          metric_name = if @payload[:result]
            "flipper.feature.#{feature_name}.enabled"
          else
            "flipper.feature.#{feature_name}.disabled"
          end

          Metriks.meter(metric_name).mark
        end
      end

      def update_adapter_operation_metrics
        # noop for now
      end

      def update_gate_operation_metrics
        # noop for now
      end
    end
  end
end
