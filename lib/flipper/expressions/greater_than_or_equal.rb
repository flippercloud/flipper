require "flipper/expression"

module Flipper
  module Expressions
    class GreaterThanOrEqual < Expression
      def evaluate(context = {})
        return false unless args[0] && args[1]

        left = evaluate_arg(0, context)
        right = evaluate_arg(1, context)

        return false unless left && right

        left >= right
      end
    end
  end
end
