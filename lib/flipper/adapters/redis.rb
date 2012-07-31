require 'set'
require 'redis'

module Flipper
  module Adapters
    class Redis
      def initialize(client)
        @client = client
      end

      def read(key)
        @client.get key
      end

      def write(key, value)
        @client.set key, value
      end

      def delete(key)
        @client.del key
      end

      def set_add(key, value)
        @client.sadd(key, value)
      end

      def set_delete(key, value)
        @client.srem(key, value)
      end

      def set_members(key)
        @client.smembers(key).map { |member| member.to_i }.to_set
      end
    end
  end
end
