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
      def open?(thing, value, options = {})
        if Types::Actor.wrappable?(thing)
          actor = Types::Actor.wrap(thing)
          feature_name = options.fetch(:feature_name)
          key = "#{feature_name}#{actor.value}"
          Zlib.crc32(key) % 100 < value
        else
          false
        end
      end

      def protects?(thing)
        thing.is_a?(Types::PercentageOfActors)
      end
    end
  end
end
