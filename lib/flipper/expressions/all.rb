require "flipper/expression"

module Flipper
  module Expressions
    class All < Expression
      def evaluate(context = {})
        args.all? { |arg| arg.evaluate(context) == true }
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
