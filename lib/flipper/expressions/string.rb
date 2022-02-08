require "flipper/expression"

module Flipper
  module Expressions
    class String < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        evaluate_arg(0, context).to_s
      end
    end
  end
end
