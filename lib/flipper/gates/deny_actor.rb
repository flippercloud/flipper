module Flipper
  module Gates
    class DenyActor < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :deny_actor
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :deny_actors
      end

      def data_type
        :set
      end

      def enabled?(value)
        !value.empty?
      end

      def open?(context)
        false
      end

      def blocks?(context)
        return false unless context.actors?

        context.actors.any? do |actor|
          context.values.deny_actors.include?(actor.value)
        end
      end

      def deny?
        true
      end

      def wrap(actor)
        Types::Actor.wrap(actor)
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end
    end
  end
end
