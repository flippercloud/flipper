require 'rack/utils'
require 'stringio'
require 'flipper/api/error_response'
require 'flipper/api/parameter_parsing'

module Flipper
  module Api
    class JsonParams
      include Rack::Utils

      def initialize(app)
        @app = app
      end

      CONTENT_TYPE = 'CONTENT_TYPE'.freeze
      CONTENT_ENCODING = 'HTTP_CONTENT_ENCODING'.freeze
      PATH_INFO = 'PATH_INFO'.freeze
      QUERY_STRING = 'QUERY_STRING'.freeze
      REQUEST_BODY = 'rack.input'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      MAX_MUTATION_BODY_BYTES = 1024 * 1024
      MUTATION_REQUEST_METHODS = ['POST'.freeze, 'PUT'.freeze, 'DELETE'.freeze].freeze
      InvalidRequestBody = Class.new(StandardError)
      private_constant :InvalidRequestBody

      # Public: Merge JSON request body params with query string params so the
      # API can handle form and JSON parameters consistently.
      def call(env)
        validate_mutation_query(env) if mutation_request?(env)

        if json_request?(env) && !import_request?(env)
          return invalid_request_response unless supported_content_encoding?(env)

          body = read_body(env, mutation_request?(env) ? MAX_MUTATION_BODY_BYTES + 1 : nil)
          if mutation_request?(env) && body.bytesize > MAX_MUTATION_BODY_BYTES
            return invalid_request_response
          end

          begin
            update_params(env, body, strict: mutation_request?(env))
          rescue InvalidRequestBody
            return invalid_request_response
          end
        end

        @app.call(env)
      rescue InvalidRequestBody
        invalid_request_response
      end

      private

      def validate_mutation_query(env)
        params = ParameterParsing.parse_nested_query(env[QUERY_STRING].to_s)
        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(params)
      rescue *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def update_params(env, data, strict:)
        return if data.empty?

        parsed_request_body = parse_json_body(data, strict: strict)
        if strict
          raise InvalidRequestBody unless parsed_request_body.is_a?(Hash)
          raise InvalidRequestBody unless ParameterParsing.valid_encoding?(parsed_request_body)

          query_params = parse_nested_query(env[QUERY_STRING].to_s)
          unless compatible_parameter_shapes?(query_params, parsed_request_body)
            raise InvalidRequestBody
          end
        end

        env["parsed_request_body".freeze] = parsed_request_body
        parsed_query_string = parse_query(env[QUERY_STRING].to_s)
        parsed_query_string.merge!(parsed_request_body)
        env[QUERY_STRING] = build_query(parsed_query_string)
        env.delete('rack.request.query_hash'.freeze)
        env.delete('rack.request.query_string'.freeze)
      rescue *ParameterParsing.errors
        raise InvalidRequestBody if strict

        raise
      end

      def parse_json_body(data, strict:)
        Typecast.from_json(data)
      rescue JSON::ParserError
        raise InvalidRequestBody if strict

        raise
      end

      def parse_nested_query(data)
        ParameterParsing.parse_nested_query(data)
      end

      def compatible_parameter_shapes?(left, right)
        (left.keys & right.keys).all? do |key|
          left_value = left[key]
          right_value = right[key]
          left_shape = parameter_shape(left_value)
          right_shape = parameter_shape(right_value)

          left_shape == right_shape &&
            (left_shape != Hash || compatible_parameter_shapes?(left_value, right_value))
        end
      end

      def parameter_shape(value)
        return Hash if value.is_a?(Hash)
        return Array if value.is_a?(Array)

        String
      end

      def read_body(env, length)
        input = env[REQUEST_BODY]
        body = length ? ParameterParsing.read_bounded(input, length) : (input.read || '')
        if input.respond_to?(:rewind)
          input.rewind
        else
          env[REQUEST_BODY] = StringIO.new(body)
        end
        body
      end

      def mutation_request?(env)
        MUTATION_REQUEST_METHODS.include?(env[REQUEST_METHOD])
      end

      def json_request?(env)
        media_type(env).casecmp('application/json') == 0
      end

      def media_type(env)
        env[CONTENT_TYPE].to_s.split(';', 2).first.to_s.strip
      end

      def import_request?(env)
        env[PATH_INFO].to_s.match?(%r{\A/import/?\z})
      end

      def supported_content_encoding?(env)
        content_encoding = env[CONTENT_ENCODING].to_s.strip.downcase
        content_encoding.empty? || content_encoding == 'identity'
      end

      def invalid_request_response
        error = ErrorResponse::ERRORS.fetch(:request_invalid)
        body = Typecast.to_json(error.as_json)
        [error.http_status, {Rack::CONTENT_TYPE => Api::CONTENT_TYPE}, [body]]
      end
    end
  end
end
