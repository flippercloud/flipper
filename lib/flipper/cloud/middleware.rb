# frozen_string_literal: true

require "flipper/cloud/message_verifier"

module Flipper
  module Cloud
    class Middleware
      # Internal: The path to match for webhook requests.
      WEBHOOK_PATH = %r{\A/webhooks\/?\Z}

      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        if request.post? && request.path_info.match(WEBHOOK_PATH)
          status = 200
          headers = {
            "Content-Type" => "application/json",
          }
          body = "{}"
          payload = request.body.read
          signature = request.env["HTTP_FLIPPER_CLOUD_SIGNATURE"]
          flipper = env.fetch(@env_key)

          begin
            message_verifier = MessageVerifier.new(secret: flipper.sync_secret)
            if message_verifier.verify(payload, signature)
              flipper.sync
            end
          rescue MessageVerifier::InvalidSignature
            status = 400
          end

          [status, headers, [body]]
        else
          @app.call(env)
        end
      end
    end
  end
end
