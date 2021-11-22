require "flipper/expression"

module Flipper
  module Expressions
    class Random < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        rand evaluate_arg(0, context)
      end
    end
  end
end
