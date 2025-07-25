module Flipper
  module Expressions
    class Boolean
      def self.call(value)
        Flipper::Typecast.to_boolean(value)
      end

      def self.in_words(arg)
        self.call(arg.value)
      end
    end
  end
end
