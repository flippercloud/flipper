require 'zlib'

module Flipper
  module Gates
    class PercentageOfActors < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :percentage_of_actors
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :percentage_of_actors
      end

      def data_type
        :integer
      end

      def enabled?(value)
        value > 0
      end

      SCALING_FACTOR = 1_000

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        return false if context.thing.nil?
        id = "#{context.feature_name}#{context.thing.value}"
        # this is to support up to 3 decimal places in percentages
        Zlib.crc32(id) % (100 * SCALING_FACTOR) < context.values.percentage_of_actors * SCALING_FACTOR
      end

      def protects?(thing)
        thing.is_a?(Types::PercentageOfActors)
      end
    end
  end
end
