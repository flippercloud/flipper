require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Neq < Base
        def initialize
          super :neq
        end

        def call(left:, right:, **)
          left != right
        end
      end
    end
  end
end
