module Flipper
  module Expressions
    class PercentageOfActors
      SCALING_FACTOR = 1_000

      def self.call(text, percentage, context: {})
        prefix = context[:feature_name] || ""
        # NOTE: `crc32 % 100_000` has a tiny modulo bias (2**32 is not a
        # multiple of 100_000, so buckets 0..67_295 are ~0.0023% over-
        # represented). Intentionally left as-is: any "fix" changes the
        # hash-to-bucket mapping and would re-bucket essentially every
        # actor on upgrade, silently flipping who is enabled. Stable,
        # deterministic bucketing matters more than perfect uniformity.
        # Keep in sync with Flipper::Gates::PercentageOfActors. Do not change.
        Zlib.crc32("#{prefix}#{text}") % (100 * SCALING_FACTOR) < percentage * SCALING_FACTOR
      end
    end
  end
end
