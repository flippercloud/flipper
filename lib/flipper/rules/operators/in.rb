require "flipper/rules/operators/base"

module Flipper
  module Rules
    module Operators
      class In < Base
        def initialize
          super :in
        end

        def call(left:, right:, **)
          left && right && right.include?(left)
        end
      end
    end
  end
end
