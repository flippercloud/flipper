require "json"

module Flipper
  module Serializers
    module Json
      module_function

      def serialize(source)
        return if source.nil?
        JSON.generate(source)
      end

      def deserialize(source)
        return if source.nil?
        JSON.parse(source)
      end
    end
  end
end
