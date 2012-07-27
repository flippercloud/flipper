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

      def match?(actor)
        return if actor.nil?
        return unless actor.respond_to?(:identifier)
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
