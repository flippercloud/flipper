module Flipper
  module Expressions
    class Number
      def self.call(value)
        # FIXME: rename to_percentage to to_number, but it does what we want
        Flipper::Typecast.to_percentage(value)
      end
    end
  end
end
