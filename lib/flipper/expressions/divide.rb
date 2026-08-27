module Flipper
  module Expressions
    class Divide
      def self.call(left, right)
        return nil if right.respond_to?(:zero?) && right.zero?

        left.fdiv(right)
      rescue NoMethodError, TypeError, ZeroDivisionError
        nil
      end
    end
  end
end
