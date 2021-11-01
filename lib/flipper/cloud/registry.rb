require "thread"

module Flipper
  module Cloud
    class Registry
      def self.default
        @default ||= new
      end

      def initialize
        @mutex = Mutex.new
        @data = {}
      end

      def fetch(key, &block)
        @mutex.synchronize do
          if data = @data[key]
            data
          else
            @data[key] = yield
          end
        end
      end

      def keys
        @mutex.synchronize do
          @data.keys
        end
      end

      def each(&block)
        data = @mutex.synchronize do
          @data.dup
        end

        data.each(&block)
      end

      def clear
        @mutex.synchronize do
          @data = {}
        end
      end
    end
  end
end
