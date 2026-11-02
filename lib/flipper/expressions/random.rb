module Flipper
  module Expressions
    class Random
      def self.call(max = 0)
        rand max
      rescue TypeError, RangeError
        nil
      end
    end
  end
end
