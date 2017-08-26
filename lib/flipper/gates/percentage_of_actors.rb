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

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        return false unless Types::Actor.wrappable?(context.thing)

        percentage = context.values[key]

        actor = Types::Actor.wrap(context.thing)
        id = "#{context.feature_name}#{actor.value}"
        # this is to support up to 3 decimal places in percentages
        scaling_factor = 1_000
        Zlib.crc32(id) % (100 * scaling_factor) < percentage * scaling_factor
      end

      def protects?(thing)
        thing.is_a?(Types::PercentageOfActors)
      end
    end
  end
end
