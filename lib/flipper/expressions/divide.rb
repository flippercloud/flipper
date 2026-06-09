module Flipper
  module Expressions
    class Divide
      def self.call(left, right)
        left.fdiv(right)
      rescue NoMethodError, TypeError, ZeroDivisionError
        nil
      end
    end
  end
end
