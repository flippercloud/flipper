module Flipper
  module Expressions
    class LessThan < Comparable
      def self.operator
        :<
      end
    end
  end
end
