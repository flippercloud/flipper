require "flipper/expression"

module Flipper
  module Expressions
    class Boolean < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        !!evaluate_arg(0, context)
      end
    end
  end
end
