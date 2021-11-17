require "flipper/expression"

module Flipper
  module Expressions
    class All < Expression
      def evaluate(feature_name: "", properties: {})
        args.all? { |arg| arg.evaluate(feature_name: feature_name, properties: properties) == true }
      end

      def any
        Expressions::Any.new([self])
      end

      def all
        self
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
