module Flipper
  module Expressions
    class Add
      def self.call(left, right)
        left + right
      rescue NoMethodError, TypeError
        nil
      end
    end
  end
end
