module Flipper
  module Instrumentors
    # Instrumentor that is useful for tests as it stores each of the events that
    # are instrumented.
    class Memory
      Event = Struct.new(:name, :payload, :result)

      attr_reader :events

      def initialize
        @events = []
      end

      def instrument(name, payload = {})
        result = yield
        @events << Event.new(name, payload, result)
        result
      end
    end
  end
end
