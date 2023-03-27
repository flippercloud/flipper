module Flipper
  class Expression
    # Public: A constant value like a "string", Number (1, 3.5), Boolean (true, false).
    #
    # Implements the same interface as Expression
    class Constant
      include Expression::Builder

      attr_reader :value

      # Override initialize to avoid trying to build args
      def initialize(value)
        @value = value
      end

      def evaluate(context = {})
        value
      end

      def eql?(other)
        other.is_a?(self.class) && other.value == value
      end
      alias_method :==, :eql?
    end
  end
end
