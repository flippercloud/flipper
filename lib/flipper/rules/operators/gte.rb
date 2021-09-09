require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Gte < Base
        def initialize
          super :gte
        end

        def call(left:, right:, **)
          left && right && left >= right
        end
      end
    end
  end
end
