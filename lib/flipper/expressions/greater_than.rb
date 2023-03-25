require "flipper/expression"

module Flipper
  module Expressions
    class GreaterThan < Comparable
      def operator
        :>
      end
    end
  end
end
