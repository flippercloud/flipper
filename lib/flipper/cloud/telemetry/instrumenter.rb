require "delegate"

module Flipper
  module Cloud
    class Telemetry
      class Instrumenter
        attr_reader :instrumenter

        def initialize(cloud_configuration, instrumenter)
          @instrumenter = instrumenter
          @cloud_configuration = cloud_configuration
        end

        def instrument(name, payload = {}, &block)
          return_value = instrumenter.instrument(name, payload, &block)
          @cloud_configuration.telemetry.record(name, payload)
          return_value
        end
      end
    end
  end
end
