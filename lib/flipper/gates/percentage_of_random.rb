module Flipper
  module Gates
    class PercentageOfRandom < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :percentage_of_random
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :percentage_of_random
      end

      def data_type
        :integer
      end

      def description(value)
        if enabled?(value)
          "#{value}% of the time"
        else
          'disabled'
        end
      end

      def enabled?(value)
        !value.nil? && value.to_i > 0
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value)
        percentage = value.to_i

        rand < (percentage / 100.0)
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfRandom)
      end
    end
  end
end
