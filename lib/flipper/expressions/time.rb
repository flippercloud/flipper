module Flipper
  module Expressions
    class Time
      def self.call(value)
        ::Time.iso8601(value)
      end
    end
  end
end
