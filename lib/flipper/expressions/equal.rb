require "flipper/expression"

module Flipper
  module Expressions
    class Equal < Expression
      def evaluate(context = {})
        return false unless args[0] && args[1]

        left = evaluate_arg(0, context)
        right = evaluate_arg(1, context)

        left == right
      end
    end
  end
end
