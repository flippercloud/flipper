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

      # Public: Validate this constant against the JSON Schema. Returns an
      # Enumerable of validation errors (empty when valid). Requires json_schemer.
      def validate
        Schema.instance.validate(value)
      end

      # Public: Returns true if this constant is a structurally valid expression.
      def valid?
        Schema.instance.valid?(value)
      end
    end
  end
end
