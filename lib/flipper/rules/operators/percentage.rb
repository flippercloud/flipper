require "zlib"
require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Percentage < Base
        SCALING_FACTOR = 1_000

        def initialize
          super :percentage
        end

        def call(left:, right:, feature_name:, **)
          return false unless left && right
          Zlib.crc32("#{feature_name}#{left}") % (100 * SCALING_FACTOR) < right * SCALING_FACTOR
        end
      end
    end
  end
end
