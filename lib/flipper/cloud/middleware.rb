module Flipper
  module Cloud
    class Middleware
      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper'.freeze)
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        if request.post? && request.path_info.match(%r{\A/webhooks\/?\Z})
          # validate request method
          # validate token
          flipper = env.fetch(@env_key)
          flipper.sync
          [200, {'Content-Type'.freeze => 'application/json'.freeze}, ['{}'.freeze]]
        else
          @app.call(env)
        end
      end
    end
  end
end
