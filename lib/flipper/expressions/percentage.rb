module Flipper
  module Expressions
    class Percentage
      def self.call(value)
        value.to_f.clamp(0, 100)
      end
    end
  end
end
