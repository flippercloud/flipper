require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Gt < Base
        def initialize
          super :gt
        end

        def call(left:, right:, **)
          left && right && left > right
        end
      end
    end
  end
end
