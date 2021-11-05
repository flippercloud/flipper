require "delegate"
require "flipper/instrumenters/noop"

module Flipper
  module Cloud
    class Instrumenter < SimpleDelegator
      def initialize(options = {})
        @brow = options.fetch(:brow)
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        super @instrumenter
      end

      def instrument(name, payload = {}, &block)
        result = @instrumenter.instrument(name, payload, &block)
        push name, payload
        result
      end

      private

      def push(name, payload)
        return unless name == Flipper::Feature::InstrumentationName
        return unless :enabled? == payload[:operation]

        dimensions = {
          "feature" => payload[:feature_name].to_s,
          "result" => payload[:result].to_s,
        }
        if (thing = payload[:thing])
          dimensions["flipper_id"] = thing.value.to_s
        end

        event = {
          type: "enabled",
          dimensions: dimensions,
          measures: {},
          ts: Time.now.utc,
        }
        @brow.push event
      end
    end
  end
end
