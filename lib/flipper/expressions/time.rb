require "time"

module Flipper
  module Expressions
    class Time
      def self.call(value)
        case value
        when Numeric
          ::Time.at(value).utc
        else
          ::Time.parse(value).utc
        end
      end
    end
  end
end
