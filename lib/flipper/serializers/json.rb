require "json"

module Flipper
  module Serializers
    class Json
      def self.serialize(source)
        return if source.nil?
        JSON.generate(source)
      end

      def self.deserialize(source)
        return if source.nil?
        JSON.parse(source)
      end
    end
  end
end
