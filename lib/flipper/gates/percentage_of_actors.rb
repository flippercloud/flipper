require 'zlib'

module Flipper
  module Gates
    class PercentageOfActors < Gate
      RAND_BASE = (2**32 - 1) / 100.0

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

        Zlib.crc32(id) < RAND_BASE * percentage
      end

      def protects?(thing)
        thing.is_a?(Types::PercentageOfActors)
      end
    end
  end
end
