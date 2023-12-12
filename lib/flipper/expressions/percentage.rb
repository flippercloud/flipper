module Flipper
  module Expressions
    class Percentage
      def self.call(value)
        value.clamp(0, 100)
      end
    end
  end
end
