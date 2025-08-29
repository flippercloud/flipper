module Flipper
  module Expressions
    class LessThanOrEqualTo < Comparable
      def self.operator
        :<=
      end

      def self.operator_in_words
        'less than or equal to'
      end
    end
  end
end
