require "flipper/expression"

module Flipper
  module Expressions
    class Random < Expression
      def initialize(args)
        super Array(args)
      end

      def evaluate(context = {})
        rand args[0]
      end
    end
  end
end
