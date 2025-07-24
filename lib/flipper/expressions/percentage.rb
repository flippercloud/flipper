module Flipper
  module Expressions
    class Percentage
      def self.call(value)
        value.to_f.clamp(0, 100)
      end

      def self.in_words(arg)
        "#{self.call(arg.value)}%"
      end
    end
  end
end
