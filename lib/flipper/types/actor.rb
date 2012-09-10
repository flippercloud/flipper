module Flipper
  module Types
    class Actor < Type
      def self.wrappable?(thing)
        thing.is_a?(Flipper::Types::Actor) ||
          thing.respond_to?(:identifier) ||
          thing.respond_to?(:to_i)
      end

      def self.wrap(thing)
        if thing.is_a?(Flipper::Types::Actor)
          thing
        else
          new(thing)
        end
      end

      attr_reader :identifier

      def initialize(thing)
        raise ArgumentError, "thing cannot be nil" if thing.nil?

        @thing = thing
        @identifier = if thing.respond_to?(:identifier)
          thing.identifier
        else
          thing
        end.to_i
      end

      def enabled_value
        @identifier
      end

      alias_method :disabled_value, :enabled_value

      def respond_to?(*args)
        super || @thing.respond_to?(*args)
      end

      def method_missing(name, *args, &block)
        @thing.send name, *args, &block
      end
    end
  end
end
