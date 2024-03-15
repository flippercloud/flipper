module Flipper
  module Adapters
    class ActorLimit < Wrapper
      LimitExceeded = Class.new(Flipper::Error)

      attr_reader :limit

      def initialize(adapter, limit = 100)
        super(adapter)
        @limit = limit
      end

      def enable(feature, gate, resource)
        if gate.is_a?(Flipper::Gates::Actor) && over_limit?(feature)
          raise LimitExceeded, "Actor limit of #{@limit} exceeded for feature #{feature.key}. See https://www.flippercloud.io/docs/features/actors#limitations"
        else
          super
        end
      end

      private

      def over_limit?(feature)
        feature.actors_value.size >= @limit
      end
    end
  end
end
