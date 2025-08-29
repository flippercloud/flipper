module Flipper
  module Expressions
    class LessThan < Comparable
      def self.operator
        :<
      end

      def self.operator_in_words
        'less than'
      end
    end
  end
end
