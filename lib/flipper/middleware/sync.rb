module Flipper
  module Middleware
    class Sync
      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')
      end

      def call(env)
        flipper = env.fetch(@env_key) { Flipper }
        poll_adapter = find_poll_adapter(flipper.adapter)

        if poll_adapter
          poll_adapter.sync { @app.call(env) }
        else
          @app.call(env)
        end
      end

      private

      # Walk the adapter stack to find a Poll adapter, which may be wrapped
      # by Strict, ActorLimit, or other Wrapper adapters.
      def find_poll_adapter(adapter)
        return adapter if adapter.respond_to?(:sync)
        return find_poll_adapter(adapter.adapter) if adapter.respond_to?(:adapter)
        nil
      end
    end
  end
end
