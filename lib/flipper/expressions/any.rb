require "flipper/expression"

module Flipper
  module Expressions
    class Any < Expression
      def evaluate(context = {})
        args.any? { |arg| arg.evaluate(context) == true }
      end

      def any
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
