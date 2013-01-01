module Flipper
  module Types
    class Actor < Type
      def self.wrappable?(thing)
        thing.is_a?(Flipper::Types::Actor) || thing.respond_to?(:id)
      end

      def self.wrap(thing)
        if thing.is_a?(Flipper::Types::Actor)
          thing
        else
          new(thing)
        end
      end

      attr_reader :value

      def initialize(thing)
        raise ArgumentError, "thing cannot be nil" if thing.nil?

        @thing = thing
        @value = thing.id.to_s
      end

      def respond_to?(*args)
        super || @thing.respond_to?(*args)
      end

      def method_missing(name, *args, &block)
        @thing.send name, *args, &block
      end
    end
  end
end
