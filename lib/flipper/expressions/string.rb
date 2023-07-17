module Flipper
  module Expressions
    class String
      def self.call(value)
        value.to_s
      end
    end
  end
end
