require "flipper/expression"

module Flipper
  module Expressions
    class LessThanOrEqual < Expression
      def evaluate(feature_name: "", properties: {})
        return false unless args[0] && args[1]

        left = args[0].evaluate(feature_name: feature_name, properties: properties)
        right = args[1].evaluate(feature_name: feature_name, properties: properties)

        left && right && left <= right
      end
    end
  end
end
