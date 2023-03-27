module Flipper
  module Expressions
    class Equal < Comparable
      def self.operator
        :==
      end
    end
  end
end
