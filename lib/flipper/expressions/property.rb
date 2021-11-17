require "flipper/expression"

module Flipper
  module Expressions
    class Property < Expression
      def initialize(args)
        super Array(args).map(&:to_s)
      end

      def evaluate(feature_name: "", properties: {})
        key = args[0]
        properties[key]
      end
    end
  end
end
