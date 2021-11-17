require "flipper/expression"

module Flipper
  module Expressions
    class Random < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(feature_name: "", properties: {})
        rand args[0]
      end
    end
  end
end
