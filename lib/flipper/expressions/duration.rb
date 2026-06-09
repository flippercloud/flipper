module Flipper
  module Expressions
    class Duration
      SECONDS_PER = {
        "second" => 1,
        "minute" => 60,
        "hour" => 3600,
        "day" => 86400,
        "week" => 604_800,
        "month" => 2_629_746, # 1/12 of a gregorian year
        "year" => 31_556_952, # length of a gregorian year (365.2425 days)
      }.freeze

      def self.call(scalar, unit)
        unit = unit.to_s.downcase.chomp("s")

        return nil unless scalar.is_a?(Numeric)
        return nil unless SECONDS_PER[unit]

        scalar * SECONDS_PER[unit]
      end
    end
  end
end
