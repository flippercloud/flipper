require "delegate"

module Flipper
  module Cloud
    class Telemetry
      class Instrumenter < SimpleDelegator
        def initialize(cloud_configuration, instrumenter)
          super instrumenter
          @cloud_configuration = cloud_configuration
        end

        def instrument(name, payload = {}, &block)
          return_value = instrumenter.instrument(name, payload, &block)
          @cloud_configuration.telemetry.record(name, payload)
          return_value
        end

        private

        def instrumenter
          __getobj__
        end
      end
    end
  end
end
