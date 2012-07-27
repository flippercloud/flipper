module Flipper
  module Gates
    class Actor < Gate
      Key = :actors

      def key
        @key ||= "#{@feature.name}.#{Key}"
      end

      def toggle
        @toggle ||= Toggles::Set.new(@feature.adapter, key)
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
        thing.is_a?(Flipper::Actor)
      end
    end
  end
end
