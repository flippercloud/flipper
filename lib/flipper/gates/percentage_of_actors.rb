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

      # Private: this constant is used to support up to 3 decimal places
      # in percentages.
      SCALING_FACTOR = 1_000
      private_constant :SCALING_FACTOR

      # Internal: Checks if the gate is open for one or more actors.
      #
      # Returns true if gate open for any actors, false if not.
      def open?(context)
        return false unless context.actors?
        id = "#{context.feature_name}#{context.actors.map(&:value).sort.join}"
        Zlib.crc32(id) % (100 * SCALING_FACTOR) < context.values.percentage_of_actors * SCALING_FACTOR
      end

      def protects?(thing)
        thing.is_a?(Types::PercentageOfActors)
      end
    end
  end
end
