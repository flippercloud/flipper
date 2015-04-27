module Flipper
  module Types
    class Boolean < Type
      def initialize(value = nil)
        @value = value.nil? ? true : value
      end
    end
  end
end
