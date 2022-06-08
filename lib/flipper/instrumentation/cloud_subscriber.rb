module Flipper
  module Instrumentation
    # Report the result of feature checks to Flipper Cloud.
    class CloudSubscriber
      def initialize(brow)
        @brow = brow
      end

      def call(name, start, finish, id, payload)
        push name, payload
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
