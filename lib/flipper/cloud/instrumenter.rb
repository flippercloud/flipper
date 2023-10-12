require "delegate"
require "flipper/instrumenters/noop"

module Flipper
  module Cloud
    class Instrumenter < SimpleDelegator
      def initialize(options = {})
        @telemetry = options.fetch(:telemetry)
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        super @instrumenter
      end

      def instrument(name, payload = {}, &block)
        begin
          return_value = @instrumenter.instrument(name, payload, &block)

          if name == Flipper::Feature::InstrumentationName && payload[:operation] == :enabled?
            @telemetry.record_enabled(payload[:feature_name].to_s, payload[:result])
          end
        ensure
          return_value
        end
      end
    end
  end
end
