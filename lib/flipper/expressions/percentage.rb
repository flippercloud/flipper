require "flipper/expression"

module Flipper
  module Expressions
    class Percentage < Expression
      SCALING_FACTOR = 1_000

      def evaluate(feature_name: "", properties: {})
        return false unless args[0] && args[1]

        left = args[0].evaluate(feature_name: feature_name, properties: properties)
        right = args[1].evaluate(feature_name: feature_name, properties: properties)

        return false unless left && right

        Zlib.crc32("#{feature_name}#{left}") % (100 * SCALING_FACTOR) < right * SCALING_FACTOR
      end
    end
  end
end
