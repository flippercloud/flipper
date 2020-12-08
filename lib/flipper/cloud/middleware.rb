module Flipper
  module Cloud
    class Middleware
      # Internal: The path to match for webhook requests.
      WEBHOOK_PATH = %r{\A/webhooks\/?\Z}

      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper'.freeze)
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        if request.post? && request.path_info.match(WEBHOOK_PATH)
          data = JSON.parse(request.body.read)
          flipper = env.fetch(@env_key)

          if data["webhook_secret"] && flipper.sync_secret == data["webhook_secret"]
            flipper.sync
            [200, {'Content-Type'.freeze => 'application/json'.freeze}, ['{}'.freeze]]
          else
            [403, {'Content-Type'.freeze => 'application/json'.freeze}, ['{}'.freeze]]
          end
        else
          @app.call(env)
        end
      end
    end
  end
end
