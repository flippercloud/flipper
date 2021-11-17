require "flipper/expression"

module Flipper
  module Expressions
    class Number < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(feature_name: "", properties: {})
        args[0]
      end
    end
  end
end
