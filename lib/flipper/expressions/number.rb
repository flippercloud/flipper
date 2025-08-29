module Flipper
  module Expressions
    class Number
      def self.call(value)
        Flipper::Typecast.to_number(value)
      end

      def self.in_words(arg)
        arg.in_words
      end
    end
  end
end
