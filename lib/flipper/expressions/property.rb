require "flipper/expression"

module Flipper
  module Expressions
    class Property < Expression
      def call(key, context:)
        if properties = context[:properties]
          properties[key.to_s]
        else
          nil
        end
      end
    end
  end
end
