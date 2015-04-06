module Flipper
  module Types
    class Actor < Type
      def self.wrappable?(thing)
        return false if thing.nil?
        return true if thing.is_a?(Flipper::Types::Actor)
        thing.respond_to?(:flipper_id)
      end

      def self.wrap(thing)
        return thing if thing.is_a?(self)
        new(thing)
      end

      attr_reader :thing
      attr_reader :value

      def initialize(thing)
        if thing.nil?
          raise ArgumentError.new("thing cannot be nil")
        end

        unless thing.respond_to?(:flipper_id)
          raise ArgumentError.new("#{thing.inspect} must respond to flipper_id, but does not")
        end

        @thing = thing
        @value = thing.flipper_id.to_s
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
