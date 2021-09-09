require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Eq < Base
        def initialize
          super :eq
        end

        def call(left:, right:, **)
          left == right
        end
      end
    end
  end
end
