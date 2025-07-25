module Flipper
  module Expressions
    class NotEqual < Comparable
      def self.operator
        :!=
      end

      def self.operator_in_words
      'not equal to'
      end
    end
  end
end
