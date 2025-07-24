module Flipper
  module Expressions
    class String
      def self.call(value)
        value.to_s
      end

      def self.in_words(arg)
        arg.in_words
      end
    end
  end
end
