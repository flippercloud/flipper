module Flipper
  module Expressions
    class NotIn
      # The negation of In: true when list is an array that does NOT contain
      # value. A non-array right (nil, string, etc.) evaluates to false so
      # malformed data fails closed rather than enabling the feature.
      def self.call(left, right)
        right.is_a?(::Array) && !right.include?(left)
      end
    end
  end
end
