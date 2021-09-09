require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class Lt < Base
        def initialize
          super :lt
        end

        def call(left:, right:, **)
          left && right && left < right
        end
      end
    end
  end
end
