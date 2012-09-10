require 'set'

module Flipper
  module Adapters
    class Memory
      def initialize(source = nil)
        @source = source || {}
      end

      def read(key)
        @source[key.to_s]
      end

      def write(key, value)
        @source[key.to_s] = value
      end

      def delete(key)
        @source.delete(key.to_s)
      end

      def set_add(key, value)
        set_members(key.to_s).add(value)
      end

      def set_delete(key, value)
        set_members(key.to_s).delete(value)
      end

      def set_members(key)
        @source[key.to_s] ||= Set.new
      end
    end
  end
end
