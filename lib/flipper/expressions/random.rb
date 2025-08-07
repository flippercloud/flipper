module Flipper
  module Expressions
    class Random
      def self.call(max = 0)
        rand max
      end

      def self.in_words(arg)
        "random(#{arg.in_words})"
      end
    end
  end
end
