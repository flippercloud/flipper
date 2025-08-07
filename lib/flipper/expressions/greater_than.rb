module Flipper
  module Expressions
    class GreaterThan < Comparable
      def self.operator
        :>
      end

      def self.operator_in_words
        'greater than'
      end
    end
  end
end
