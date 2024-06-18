module Flipper
  module Expressions
    class Include < Comparable
      def self.operator
        :include?
      end
    end
  end
end
