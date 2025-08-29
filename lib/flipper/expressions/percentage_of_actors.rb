module Flipper
  module Expressions
    class PercentageOfActors
      SCALING_FACTOR = 1_000

      def self.call(text, percentage, context: {})
        prefix = context[:feature_name] || ""
        Zlib.crc32("#{prefix}#{text}") % (100 * SCALING_FACTOR) < percentage * SCALING_FACTOR
      end

      def self.in_words(arg1, arg2)
        "#{arg1.in_words} in #{arg2.in_words}% of actors"
      end
    end
  end
end
