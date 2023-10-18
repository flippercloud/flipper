require "delegate"

module Flipper
  module Cloud
    class Telemetry
      class Instrumenter < SimpleDelegator
        def initialize(cloud_configuration, instrumenter)
          super cloud_configuration
          @instrumenter = instrumenter
        end

        def instrument(name, payload = {}, &block)
          return_value = @instrumenter.instrument(name, payload, &block)
          config.telemetry.record(name, payload)
          return_value
        end

        private

        # Flipper::Cloud::Configuration instance passed to this instrumenter.
        def config
          __getobj__
        end
      end
    end
  end
end
