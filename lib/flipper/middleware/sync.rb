module Flipper
  module Middleware
    class Sync
      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')
      end

      def call(env)
        flipper = env.fetch(@env_key) { Flipper }
        if flipper.adapter.respond_to?(:sync)
          flipper.adapter.sync { @app.call(env) }
        else
          @app.call(env)
        end
      end
    end
  end
end
