require "json"

module Flipper
  module Serializers
    module Json
      module_function

      def serialize(source)
        JSON.generate(source)
      end

      def deserialize(source)
        JSON.parse(source)
      end
    end
  end
end
