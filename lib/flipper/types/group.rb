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

      def value
        @name
      end
    end
  end
end
