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

        # enabled? event shows up as actors
        now = Time.now.utc
        if (actors = payload[:actors])
          dimensions["flipper_id"] = actors.first.value.to_s
          dimensions["flipper_ids"] = actors.map { |actor| actor.value.to_s }
          event = {
            type: "enabled",
            dimensions: dimensions,
            measures: {},
            ts: now,
          }
          @brow.push event
        else
          event = {
            type: "enabled",
            dimensions: dimensions,
            measures: {},
            ts: now,
          }
          @brow.push event
        end
      end
    end
  end
end
