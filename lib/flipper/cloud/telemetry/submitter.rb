require "securerandom"
require "flipper/typecast"
require "flipper/cloud/telemetry/backoff_policy"

module Flipper
  module Cloud
    class Telemetry
      class Submitter
        PATH = "/telemetry".freeze
        SCHEMA_VERSION = "V1".freeze
        GZIP_ENCODING = "gzip".freeze

        MIN_RETRY_DELAY = 2
        MAX_RETRY_DELAY = 120

        Error = Class.new(StandardError) do
          attr_reader :request_id, :response

          def initialize(request_id, response)
            @request_id = request_id
            @response = response
            super "Unexpected response code=#{response.code} request_id=#{request_id}"
          end
        end

        attr_reader :cloud_configuration, :request_id, :backoff_policy

        def initialize(cloud_configuration, backoff_policy: nil)
          @cloud_configuration = cloud_configuration
          @backoff_policy = backoff_policy || BackoffPolicy.new
          reset
        end

        def call(drained)
          return if drained.empty?
          body = to_body(drained)
          retry_with_backoff(10) { submit(body) }
        ensure
          reset
        end

        def reset
          @backoff_policy.reset
          @request_id = SecureRandom.uuid
        end

        private

        def submit(body)
          client = @cloud_configuration.http_client
          client.add_header :schema_version, SCHEMA_VERSION
          client.add_header :content_encoding, GZIP_ENCODING

          response = client.post PATH, body
          code = response.code.to_i

          # what about redirects?
          if code < 200 || code == 429 || code >= 500
            raise Error, request_id, response
          end

          response
        end

        def retry_with_backoff(attempts, &block)
          result, caught_exception = nil
          should_retry = false
          attempts_remaining = attempts - 1

          begin
            result, should_retry = yield
            return [result, nil] unless should_retry
          rescue => error
            logger.error "name=flipper_telemetry action=post_to_cloud attempts_remaining=#{attempts_remaining} error=#{error.inspect}"
            should_retry = true
            caught_exception = error
          end

          if should_retry && attempts_remaining > 0
            sleep @backoff_policy.next_interval.to_f / 1000
            retry_with_backoff attempts_remaining, &block
          else
            [result, caught_exception]
          end
        end

        def to_body(drained)
          enabled_metrics = drained.map { |metric, value|
            metric.as_json(with: {"value" => value})
          }

          json = Typecast.to_json({
            request_id: request_id,
            enabled_metrics: enabled_metrics,
          })

          Typecast.to_gzip(json)
        rescue => exception
          error(exception)
          return
        end

        def debug(message)
          logger.debug { "name=flipper_telemetry action=post_to_cloud #{message}" }
        end

        def error(error)
          logger.error "name=flipper_telemetry action=post_to_cloud request_id=#{request_id} error=#{error.inspect}"
        end

        def logger
          @cloud_configuration.telemetry_logger
        end
      end
    end
  end
end
