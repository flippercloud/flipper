module Flipper
  module Expressions
    class Number
      def self.call(value)
        Flipper::Typecast.to_number(value)
      end
    end
  end
end
