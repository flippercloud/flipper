module Flipper
  module Adapters
    module RedisShared
      def with_connection(&block)
        @client.respond_to?(:with) ? @client.with(&block) : yield(@client)
      end
    end
  end
end
