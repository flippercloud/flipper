require "flipper/expression"

module Flipper
  module Expressions
    class LessThanOrEqualTo < Comparable
      def operator
        :<=
      end
    end
  end
end
