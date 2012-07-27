module Flipper
  module Types
    class Actor < Type
      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
      end

      def enabled_value
        @identifier
      end

      alias_method :disabled_value, :enabled_value
    end
  end
end
