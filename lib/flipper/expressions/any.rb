require "flipper/expression"

module Flipper
  module Expressions
    class Any < Expression
      def evaluate(feature_name: "", properties: {})
        args.any? { |arg| arg.evaluate(feature_name: feature_name, properties: properties) == true }
      end

      def any
        self
      end

      def all
        Expressions::All.new([self])
      end

      def add(*expressions)
        self.class.new(args + expressions.flatten)
      end

      def remove(*expressions)
        self.class.new(args - expressions.flatten)
      end
    end
  end
end
