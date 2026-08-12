module Flipper
  module Expressions
    class Subtract
      def self.call(left, right)
        left - right
      rescue NoMethodError, TypeError
        nil
      end
    end
  end
end
