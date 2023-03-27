module Flipper
  module Expressions
    class PercentageOfActors
      SCALING_FACTOR = 1_000

      def self.call(text, percentage, context: {})
        prefix = context[:feature_name] || ""
        Zlib.crc32("#{prefix}#{text}") % (100 * SCALING_FACTOR) < percentage * SCALING_FACTOR
      end
    end
  end
end
