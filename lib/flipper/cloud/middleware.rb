# frozen_string_literal: true

require "flipper/cloud/message_verifier"

module Flipper
  module Cloud
    class Middleware
      # Internal: The path to match for webhook requests.
      WEBHOOK_PATH = %r{\A/webhooks\/?\Z}
      # Internal: The root path to match for requests.
      ROOT_PATH = %r{\A/\Z}
      # Internal: Number of seconds a signed webhook remains valid. Bounds the
      # window in which a captured, validly-signed request can be replayed,
      # while staying loose enough to tolerate delivery retries and clock skew.
      DEFAULT_SIGNATURE_TOLERANCE = 60 * 5

      def initialize(app, options = {})
        @app = app
        @env_key = options.fetch(:env_key, 'flipper')
        @signature_tolerance = options.fetch(:signature_tolerance, DEFAULT_SIGNATURE_TOLERANCE)
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        request = Rack::Request.new(env)
        if request.post? && (request.path_info.match(ROOT_PATH) || request.path_info.match(WEBHOOK_PATH))
          status = 200
          headers = {
            Rack::CONTENT_TYPE => "application/json",
          }
          body = "{}"
          payload = request.body.read
          signature = request.env["HTTP_FLIPPER_CLOUD_SIGNATURE"]
          flipper = env.fetch(@env_key)

          begin
            message_verifier = MessageVerifier.new(secret: flipper.sync_secret)
            if message_verifier.verify(payload, signature, tolerance: @signature_tolerance)
              begin
                flipper.sync(cache_bust: true)
                body = JSON.generate({
                  groups: Flipper.group_names.map { |name| {name: name}}
                })
              rescue Flipper::Adapters::Http::Error => error
                status = error.response.code.to_i == 402 ? 402 : 500
                headers["flipper-cloud-response-error-class"] = error.class.name
                headers["flipper-cloud-response-error-message"] = error.message
              rescue => error
                status = 500
                headers["flipper-cloud-response-error-class"] = error.class.name
                headers["flipper-cloud-response-error-message"] = error.message
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
