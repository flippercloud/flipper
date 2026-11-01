require "time"

module Flipper
  module Expressions
    class Time
      # Returns the value as a UTC time, or nil when it can't be read as one, so
      # a missing or malformed property fails comparisons instead of the check.
      def self.call(value)
        case value
        when Numeric
          ::Time.at(value).utc
        when ::String
          ::Time.parse(value).utc
        else
          value.to_time.utc if value.respond_to?(:to_time)
        end
      rescue ArgumentError
        nil
      end
    end
  end
end
