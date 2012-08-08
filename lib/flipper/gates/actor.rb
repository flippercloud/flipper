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

      def open?(actor)
        return if actor.nil?
        return unless Types::Actor.wrappable?(actor)
        actor = Types::Actor.wrap(actor)
        identifiers.include?(actor.identifier)
      end

      def identifiers
        toggle.value
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Actor)
      end
    end
  end
end
