require "flipper/expression"

module Flipper
  module Expressions
    class GreaterThanOrEqualTo < Comparable
      def operator
        :>=
      end
    end
  end
end
