require "flipper/expression"

module Flipper
  module Expressions
    class PercentageOfActors < Expression
      SCALING_FACTOR = 1_000

      def evaluate(context = {})
        return false unless args[0] && args[1]

        text = evaluate_arg(0, context)
        percentage = evaluate_arg(1, context)

        return false unless text && percentage

        prefix = context[:feature_name] || ""
        Zlib.crc32("#{prefix}#{text}") % (100 * SCALING_FACTOR) < percentage * SCALING_FACTOR
      end
    end
  end
end
