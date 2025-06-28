module Flipper
  module Adapters
    module RedisShared
      private

      # Safely executes a block with a Redis connection, handling compatibility
      # issues between different Redis client versions and Rails versions.
      #
      # This method exists to fix a compatibility issue between Rails 7.1.* and
      # Redis versions below 4.7.0. The issue occurs because:
      #
      # 1. In Redis versions below 4.7.0, the `with` method is not defined on
      #    the Redis client, so Flipper would fall back to `yield(@client)`
      # 2. However, Rails 7.1.* introduced `Object#with` via ActiveSupport,
      #    which shadows the Redis client's `with` method
      # 3. Rails 7.1.*'s `Object#with` doesn't pass `self` to the block parameter
      #    (this was fixed in Rails 7.2.0), causing the block parameter to be `nil`
      #
      # This method ensures that:
      # - For Redis >= 4.7.0: Uses the Redis client's native `with` method
      # - For ConnectionPool: Uses the ConnectionPool's `with` method
      # - For Redis < 4.7.0: Falls back to `yield(@client)` to avoid the Rails
      #   ActiveSupport `Object#with` method
      #
      # @see https://github.com/redis/redis-rb/blob/master/CHANGELOG.md#470
      # @see https://github.com/rails/rails/pull/46681
      # @see https://github.com/rails/rails/pull/50470
      def with_connection(&block)
        if client_has_correct_with_method?
          @client.with(&block)
        else
          yield(@client)
        end
      end

      # Determines if the Redis client has a safe `with` method that can be used
      # without conflicts with Rails ActiveSupport's `Object#with`.
      #
      # This method checks for:
      # 1. ConnectionPool instances (which have their own `with` method)
      # 2. Redis instances with version >= 4.7.0 (which have a proper `with` method)
      #
      # The method caches its result to avoid repeated checks.
      #
      # @return [Boolean] true if the client has a safe `with` method, false otherwise
      def client_has_correct_with_method?
        return @client_has_correct_with_method if defined?(@client_has_correct_with_method)

        @client_has_correct_with_method = @client.respond_to?(:with) && (client_is_connection_pool? || client_is_redis_that_has_with?)
      rescue
        @client_has_correct_with_method = false
      end

      def client_is_connection_pool?
        defined?(ConnectionPool) && @client.is_a?(ConnectionPool)
      end

      def client_is_redis_that_has_with?
        @client.is_a?(::Redis) && defined?(::Redis::VERSION) &&
          ::Gem::Version.new(::Redis::VERSION) >= ::Gem::Version.new('4.7.0')
      end
    end
  end
end
