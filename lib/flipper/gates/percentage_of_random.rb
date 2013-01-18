module Flipper
  module Gates
    class PercentageOfRandom < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :percentage_of_random
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :perc_time
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing)
        instrument(:open, thing) {
          percentage = toggle.value.to_i

          rand < (percentage / 100.0)
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfRandom)
      end

      def description
        if enabled?
          "#{toggle.value}% of the time"
        else
          'Disabled'
        end
      end
    end
  end
end
