module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and raises for any writes.
    class ReadOnly
      include ::Flipper::Adapter

      class WriteAttempted < Error
        def initialize(message = nil)
          super(message || "write attempted while in read only mode")
        end
      end

      # Internal: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter)
        @adapter = adapter
        @name = :read_only
      end

      def features
        @adapter.features
      end

      def get(feature)
        @adapter.get(feature)
      end

      def get_control(control)
        @adapter.get_control(control)
      end

      def add(feature)
        raise WriteAttempted
      end

      def remove(feature)
        raise WriteAttempted
      end

      def clear(feature)
        raise WriteAttempted
      end

      def enable(feature, gate, thing)
        raise WriteAttempted
      end

      def disable(feature, gate, thing)
        raise WriteAttempted
      end

      def set_control(control, value)
        raise WriteAttempted
      end
    end
  end
end
