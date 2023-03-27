require "flipper/expression"

module Flipper
  module Expressions
    class Now
      def self.call
        ::Time.now
      end
    end
  end
end
