require 'flipper/rules/object'

module Flipper
  module Rules
    class Random < Object
      def initialize(value)
        @type = "random".freeze
        @value = value
      end
    end
  end
end
