module Flipper
  module Expressions
    class Subtract
      def self.call(left, right)
        left - right
      end
    end
  end
end
