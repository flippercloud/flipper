require "flipper/expression"

module Flipper
  module Expressions
    class LessThan < Expression
      def evaluate(context = {})
        return false unless args[0] && args[1]

        left = args[0].evaluate(context)
        right = args[1].evaluate(context)

        left && right && left < right
      end
    end
  end
end
