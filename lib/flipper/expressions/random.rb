module Flipper
  module Expressions
    class Random
      def self.call(max = 0)
        rand max
      end
    end
  end
end
