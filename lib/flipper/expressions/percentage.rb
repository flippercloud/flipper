module Flipper
  module Expressions
    class Percentage
      def self.call(value)
        Flipper::Typecast.to_float(value).clamp(0, 100)
      rescue ArgumentError
        0
      end
    end
  end
end
