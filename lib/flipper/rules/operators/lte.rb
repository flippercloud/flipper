require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Lte < Base
        def initialize
          super :lte
        end

        def call(left:, right:, **)
          left && right && left <= right
        end
      end
    end
  end
end
