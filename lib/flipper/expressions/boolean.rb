module Flipper
  module Expressions
    class Boolean
      def self.call(value)
        Flipper::Typecast.to_boolean(value)
      end
    end
  end
end
