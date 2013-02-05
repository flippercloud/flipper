require 'zlib'

module Flipper
  module Gates
    class PercentageOfActors < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :percentage_of_actors
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :perc_actors
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing)
        instrument(:open?, thing) { |payload|
          percentage = toggle.value.to_i

          if Types::Actor.wrappable?(thing)
            actor = Types::Actor.wrap(thing)
            key = "#{@feature.name}#{actor.value}"
            Zlib.crc32(key) % 100 < percentage
          else
            false
          end
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfActors)
      end

      def description
        if enabled?
          "#{toggle.value}% of actors"
        else
          'disabled'
        end
      end
    end
  end
end
