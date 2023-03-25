require "flipper/expression"

module Flipper
  module Expressions
    class Comparable < Expression
      def operator
        raise NotImplementedError
      end

      def call(left, right)
        left.respond_to?(operator) && right.respond_to?(operator) && left.public_send(operator, right)
      end
    end
  end
end
