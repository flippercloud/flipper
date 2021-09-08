require 'flipper/rules/object'

module Flipper
  module Rules
    class Random < Object
      def initialize(value)
        @type = "Random".freeze
        @value = value
      end

      def evaluate(properties)
        rand value
      end
    end
  end
end
