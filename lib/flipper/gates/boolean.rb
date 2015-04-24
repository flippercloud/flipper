module Flipper
  module Gates
    class Boolean < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :boolean
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :boolean
      end

      def data_type
        :boolean
      end

      def enabled?(value)
        Typecast.to_boolean(value)
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if explicitly set to true, false if explicitly set to false
      # or nil if not explicitly set.
      def open?(thing, value, options = {})
        value
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Boolean)
      end
    end
  end
end
