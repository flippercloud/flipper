module Flipper
  module Expressions
    class Comparable
      def self.operator
        raise NotImplementedError
      end

      def self.call(left, right)
        left.respond_to?(operator) && right.respond_to?(operator) && left.public_send(operator, right)
      end

      def self.in_words(left, right)
        "#{left.in_words} is #{operator_in_words} #{right.in_words}"
      end

      def self.operator_in_words
        raise NotImplementedError
      end
    end
  end
end
