require "flipper/expression"

module Flipper
  module Expressions
    class Time < Expression
      def initialize(args)
        super [args].flatten.map(&:to_s)
      end

      def evaluate(context = {})
        ::Time.parse(evaluate_arg(0, context))
      end
    end
  end
end
