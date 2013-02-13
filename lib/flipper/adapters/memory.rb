require 'set'

module Flipper
  module Adapters
    class Memory
      # Public
      def initialize(source = nil)
        @source = source || {}
      end

      # Public
      def get(feature)
        result = {}
        feature.gates.each do |gate|
          result[gate] = gate.value
        end
        result
      end

      # Public
      def read(key)
        @source[key.to_s]
      end

      # Public
      def write(key, value)
        @source[key.to_s] = value.to_s
      end

      # Public
      def delete(key)
        @source.delete(key.to_s)
      end

      # Public
      def set_add(key, value)
        ensure_set_initialized(key)
        @source[key.to_s].add(value.to_s)
      end

      # Public
      def set_delete(key, value)
        ensure_set_initialized(key)
        @source[key.to_s].delete(value.to_s)
      end

      # Public
      def set_members(key)
        ensure_set_initialized(key)
        @source[key.to_s]
      end

      private

      def ensure_set_initialized(key)
        @source[key.to_s] ||= Set.new
      end
    end
  end
end
