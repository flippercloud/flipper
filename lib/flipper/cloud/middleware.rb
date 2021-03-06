# frozen_string_literal: true

require "flipper/cloud/message_verifier"

module Flipper
  module Cloud
    class Middleware
      # Internal: The path to match for webhook requests.
      WEBHOOK_PATH = %r{\A/webhooks\/?\Z}
      # Internal: The root path to match for requests.
      ROOT_PATH = %r{\A/\Z}

      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        if request.post? && (request.path_info.match(ROOT_PATH) || request.path_info.match(WEBHOOK_PATH))
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
              begin
                flipper.sync
                body = JSON.generate({
                  groups: Flipper.group_names.map { |name| {name: name}}
                })
              rescue Flipper::Adapters::Http::Error => error
                status = error.response.code.to_i == 402 ? 402 : 500
                headers["Flipper-Cloud-Response-Error-Class"] = error.class.name
                headers["Flipper-Cloud-Response-Error-Message"] = error.message
              rescue => error
                status = 500
                headers["Flipper-Cloud-Response-Error-Class"] = error.class.name
                headers["Flipper-Cloud-Response-Error-Message"] = error.message
              end
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
