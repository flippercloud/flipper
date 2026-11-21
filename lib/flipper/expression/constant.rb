module Flipper
  class Expression
    # Public: A constant value like a "string", Number (1, 3.5), Boolean (true, false).
    #
    # Implements the same interface as Expression
    class Constant
      include Expression::Builder

      attr_reader :value

      def initialize(value)
        @value = value
      end

      def evaluate(_ = nil)
        value
      end

      def eql?(other)
        other.is_a?(self.class) && other.value == value
      end
      alias_method :==, :eql?

      # eql? uses ==, so 1 and 1.0 are equal. Hash numbers as floats so
      # they hash the same too.
      def hash
        [self.class, value.is_a?(Numeric) && value.real? ? value.to_f : value].hash
      end
    end
  end
end
