require "flipper/expression"

module Flipper
  module Expressions
    class LessThan < Comparable
      def operator
        :<
      end
    end
  end
end
