module Flipper
  module Gates
    class Actor < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :actor
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :actors
      end

      def data_type
        :set
      end

      def enable(thing)
        thing = Types::Actor.wrap(thing)
        adapter.set_add adapter_key, thing.value
        true
      end

      def disable(thing)
        thing = Types::Actor.wrap(thing)
        adapter.set_delete adapter_key, thing.value
        true
      end

      def enabled?
        !value.empty?
      end

      def value
        adapter.set_members adapter_key
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value)
        instrument(:open?, thing) { |payload|
          if thing.nil?
            false
          else
            if Types::Actor.wrappable?(thing)
              actor = typecast(thing)
              enabled_actor_ids = value
              enabled_actor_ids.include?(actor.value)
            else
              false
            end
          end
        }
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end

      def typecast(thing)
        Types::Actor.wrap(thing)
      end

      def description
        if enabled?
          actor_ids = value.to_a.sort.map { |id| id.inspect }
          "actors (#{actor_ids.join(', ')})"
        else
          'disabled'
        end
      end
    end
  end
end
