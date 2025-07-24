module Flipper
  module Expressions
    class Property
      def self.call(key, context:)
        context.dig(:properties, key.to_s)
      end

      def self.in_words(arg)
        arg.in_words
      end
    end
  end
end
