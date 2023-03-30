module Flipper
  module Expressions
    class Time
      def self.call(value)
        ::Time.parse(value)
      end
    end
  end
end
