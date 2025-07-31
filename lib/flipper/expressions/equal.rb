module Flipper
  module Expressions
    class Equal < Comparable
      def self.operator
        :==
      end

      def self.operator_in_words
        'equal to'
      end
    end
  end
end
