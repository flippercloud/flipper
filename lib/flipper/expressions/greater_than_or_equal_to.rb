module Flipper
  module Expressions
    class GreaterThanOrEqualTo < Comparable
      def self.operator
        :>=
      end

      def self.operator_in_words
        'greater than or equal to'
      end
    end
  end
end
