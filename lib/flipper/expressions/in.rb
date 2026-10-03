module Flipper
  module Expressions
    class In
      # In(value, list) returns true when list is an array that contains value.
      # This is the "is one of" / SQL IN check: the property value on the left,
      # a static array on the right. Anything but an array on the right (nil,
      # string, etc.) evaluates to false rather than duck-typing include?.
      def self.call(left, right)
        right.is_a?(::Array) && right.include?(left)
      end
    end
  end
end
