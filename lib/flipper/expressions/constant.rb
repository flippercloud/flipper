module Flipper
  module Expressions
    # Public: Represents a constant value.
    class Constant < Expression
      # Override initialize to avoid trying to build args
      def initialize(value)
        @args = Array(value)
      end

      def evaluate(context = {})
        args[0]
      end

      def value
        args[0]
      end
    end
  end
end
