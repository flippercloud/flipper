module Flipper
  module Expressions
    class Property
      def self.call(key, context:)
        context.dig(:properties, key.to_s)
      end
    end
  end
end
