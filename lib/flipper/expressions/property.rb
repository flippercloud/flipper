require "flipper/expression"

module Flipper
  module Expressions
    class Property < Expression
      def initialize(args)
        super Array(args).map(&:to_s)
      end

      def evaluate(context = {})
        key = args[0]

        if properties = context[:properties]
          properties[key]
        else
          nil
        end
      end
    end
  end
end
