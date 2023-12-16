module Flipper
  module Expressions
    class LessThanOrEqualTo < Comparable
      def self.operator
        :<=
      end
    end
  end
end
