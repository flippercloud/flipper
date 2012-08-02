module Flipper
  module Types
    class Group < Type
      attr_reader :name

      def initialize(name, &block)
        @name = name.to_sym
        @block = block
      end

      def match?(*args)
        @block.call(*args) == true
      end

      def enabled_value
        @name
      end

      alias_method :disabled_value, :enabled_value
    end
  end
end
