module Flipper
  module Gates
    class Actor < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :actor
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :actors
      end

      def data_type
        :set
      end

      def description(value)
        if enabled?(value)
          actor_ids = value.to_a.sort.map { |id| id.inspect }
          "actors (#{actor_ids.join(', ')})"
        else
          'disabled'
        end
      end

      def enabled?(value)
        !GateValues.to_set(value).empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value)
        instrument(:open?, thing) { |payload|
          if thing.nil?
            false
          else
            if protects?(thing)
              actor = wrap(thing)
              enabled_actor_ids = value
              enabled_actor_ids.include?(actor.value)
            else
              false
            end
          end
        }
      end

      def wrap(thing)
        Types::Actor.wrap(thing)
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end
    end
  end
end
