module Flipper
  module Gates
    class Actor < Gate
      Key = :actors

      def type_key
        Key
      end

      def toggle_class
        Toggles::Set
      end

      def open?(thing)
        return if thing.nil?
        return unless Types::Actor.wrappable?(thing)
        actor = Types::Actor.wrap(thing)
        ids.include?(actor.value)
      end

      def ids
        toggle.value
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end

      def enable(thing)
        toggle.enable Types::Actor.wrap(thing)
      end

      def disable(thing)
        toggle.disable Types::Actor.wrap(thing)
      end
    end
  end
end
