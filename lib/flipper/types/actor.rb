module Flipper
  module Types
    class Actor < Type
      def self.wrappable?(actor)
        return false if actor.nil?
        actor.respond_to?(:flipper_id)
      end

      attr_reader :actor

      def initialize(actor)
        raise ArgumentError, 'actor cannot be nil' if actor.nil?

        unless actor.respond_to?(:flipper_id)
          raise ArgumentError, "#{actor.inspect} must respond to flipper_id, but does not"
        end

        @actor = actor
        @value = actor.flipper_id.to_s
      end

      def respond_to?(*args)
        super || @actor.respond_to?(*args)
      end

      if RUBY_VERSION >= '3.0'
        def method_missing(name, *args, **kwargs, &block)
          @actor.send name, *args, **kwargs, &block
        end
      else
        def method_missing(name, *args, &block)
          @actor.send name, *args, &block
        end
      end
    end
  end
end
