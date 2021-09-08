require 'flipper/rules/object'

module Flipper
  module Rules
    class Property < Object
      def initialize(value)
        @type = "Property".freeze
        @value = value.to_s
      end

      def name
        @value
      end

      def evaluate(properties)
        properties[value]
      end
    end
  end
end
