module Flipper
  module Expressions
    class GreaterThanOrEqualTo < Comparable
      def self.operator
        :>=
      end
    end
  end
end
