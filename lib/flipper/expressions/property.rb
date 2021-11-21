require "flipper/expression"

module Flipper
  module Expressions
    class Property < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        key = evaluate_arg(0, context)

        if properties = context[:properties]
          properties[key]
        else
          nil
        end
      end
    end
  end
end
