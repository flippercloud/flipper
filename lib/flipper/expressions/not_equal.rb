module Flipper
  module Expressions
    class NotEqual < Comparable
      def self.operator
        :!=
      end
    end
  end
end
