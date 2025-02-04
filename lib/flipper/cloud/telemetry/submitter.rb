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
          @request_id = SecureRandom.uuid
        end

        # Returns Array of [response, error]. response and error could be nil
        # but usually one or the other will be present.
        def call(drained)
          return if drained.empty?
          body = to_body(drained)
          return if body.nil? || body.empty?
          retry_with_backoff(5) { submit(body) }
        end

        private

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
          @cloud_configuration.instrument "telemetry_error.#{Flipper::InstrumentationNamespace}", exception: exception, request_id: request_id
          @cloud_configuration.log "action=to_body request_id=#{request_id} error=#{exception.inspect}", level: :error
        end

        def retry_with_backoff(attempts, &block)
          result, caught_exception = nil
          should_retry = false
          attempts_remaining = attempts - 1

          begin
            result, should_retry = yield
            return [result, nil] unless should_retry
          rescue => error
            @cloud_configuration.instrument "telemetry_retry.#{Flipper::InstrumentationNamespace}", attempts_remaining: attempts_remaining, exception: error
            @cloud_configuration.log "action=post_to_cloud attempts_remaining=#{attempts_remaining} error=#{error.inspect}", level: :error
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

        def submit(body)
          client = @cloud_configuration.http_client
          client.add_header "schema-version", SCHEMA_VERSION
          client.add_header "content-encoding", GZIP_ENCODING

          response = client.post PATH, body
          code = response.code.to_i

          # Raise error and retry for retriable status codes.
          # FIXME: what about redirects?
          if code < 200 || code == 429 || code >= 500
            raise Error.new(request_id, response)
          end

          response
        end
      end
    end
  end
end
