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

      def description(value)
        if enabled?(value)
          "#{value}% of actors"
        else
          'disabled'
        end
      end

      def enabled?(value)
        GateValues.to_integer(value) > 0
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value, options = {})
        instrument(:open?, thing) { |payload|
          feature_name = options.fetch(:feature_name)
          payload[:feature_name] = feature_name
          percentage = value.to_i

          if Types::Actor.wrappable?(thing)
            actor = Types::Actor.wrap(thing)
            key = "#{feature_name}#{actor.value}"
            Zlib.crc32(key) % 100 < percentage
          else
            false
          end
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::PercentageOfActors)
      end
    end
  end
end
