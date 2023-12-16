module Flipper
  module Expressions
    class GreaterThan < Comparable
      def self.operator
        :>
      end
    end
  end
end
