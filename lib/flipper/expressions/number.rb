require "flipper/expression"

module Flipper
  module Expressions
    class Number < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        evaluate_arg(0, context).to_f
      end
    end
  end
end
