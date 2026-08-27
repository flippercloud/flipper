module Flipper
  module Expressions
    class Exclude
      # The negation of Include: true when Include would be false. A missing
      # property (nil), a hash, or a number all "exclude" the value, mirroring
      # how NotEqual treats a missing property as not equal.
      def self.call(left, right)
        !Include.call(left, right)
      end
    end
  end
end
