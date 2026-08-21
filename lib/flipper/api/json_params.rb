require 'rack/utils'
require 'rack/request'
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
      QUERY_STRING = 'QUERY_STRING'.freeze
      REQUEST_BODY = 'rack.input'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      PATH_INFO = 'PATH_INFO'.freeze
      CONTENT_ENCODING = 'HTTP_CONTENT_ENCODING'.freeze
      # Gate mutations are tiny, including practical expression payloads.
      # Imports retain their separate 50 MiB streaming limit.
      MAX_MUTATION_BODY_BYTES = 1024 * 1024
      MUTATION_REQUEST_METHODS = ['POST'.freeze, 'PUT'.freeze, 'DELETE'.freeze].freeze
      InvalidRequestBody = Class.new(StandardError)
      private_constant :InvalidRequestBody

      # Public: Merge request body params with query string params
      # This way can access all params with Rack::Request#params
      # Rack does not add application/json params to Rack::Request#params
      # Allows app to handle x-www-url-form-encoded / application/json request
      # parameters the same way
      def call(env)
        return invalid_request_response unless prepare_request(env)

        @app.call(env)
      end

      private

      def prepare_request(env)
        if mutation_request?(env)
          validate_query_params(env)
          body = prepare_mutation_body(env)
        end

        if json_request?(env) && !import_request?(env)
          body ||= read_body(env)
          update_params(env, body)
        end
        true
      rescue JSON::ParserError, InvalidRequestBody
        false
      end

      def validate_query_params(env)
        parsed = ParameterParsing.parse_nested_query(env[QUERY_STRING].to_s)
        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(parsed)
      rescue *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def prepare_mutation_body(env)
        content_encoding = env[CONTENT_ENCODING].to_s.strip.downcase
        raise InvalidRequestBody unless content_encoding.empty? || content_encoding == 'identity'
        return if import_request?(env)

        body = read_body(env, MAX_MUTATION_BODY_BYTES + 1)
        raise InvalidRequestBody if body.bytesize > MAX_MUTATION_BODY_BYTES
        validate_form_params(env, body) if form_request?(env)
        validate_multipart_params(env, body) if multipart_request?(env)
        body
      end

      def validate_form_params(env, body)
        query = env[QUERY_STRING].to_s
        combined = [query, body].reject(&:empty?).join('&')
        parsed = ParameterParsing.parse_nested_query(combined)
        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(parsed)
      rescue *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def validate_multipart_params(env, body)
        return if body.empty?

        original, reversed, empty = normalized_multipart_bodies(env, body)
        body_params = empty ? {} : parse_multipart(env, original)
        parse_multipart(env, reversed) if reversed
        query_params = ParameterParsing.parse_nested_query(env[QUERY_STRING].to_s)

        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(body_params)
        raise InvalidRequestBody unless compatible_parameter_shapes?(query_params, body_params)
        cache_multipart_params(env, body_params)
      rescue EOFError, *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def normalized_multipart_bodies(env, body)
        match = env[CONTENT_TYPE].to_s.match(/boundary=(?:"([^"]*)"|([^;]*))/i)
        raise InvalidRequestBody unless match

        boundary = (match[1] || match[2]).to_s.strip
        raise InvalidRequestBody if boundary.empty?

        closing_only = "--#{boundary}--"
        if body == closing_only || body == "#{closing_only}\r\n"
          return [body, nil, true]
        end

        opening = "--#{boundary}\r\n"
        separator = "\r\n--#{boundary}\r\n"
        closing = "\r\n--#{boundary}--"
        trailer = body.end_with?("#{closing}\r\n") ? "#{closing}\r\n" : closing
        raise InvalidRequestBody unless body.start_with?(opening) && body.end_with?(trailer)

        contents_size = body.bytesize - opening.bytesize - trailer.bytesize
        raise InvalidRequestBody if contents_size < 0
        contents = body.byteslice(opening.bytesize, contents_size)
        parts = contents.split(separator, -1)
        parts.each { |part| validate_multipart_part!(part) }

        reversed = if parts.length > 1
          "#{opening}#{parts.reverse.join(separator)}#{trailer}"
        end
        [body, reversed, false]
      end

      def validate_multipart_part!(part)
        headers, separator, = part.partition("\r\n\r\n")
        raise InvalidRequestBody if separator.empty?

        dispositions = headers.scan(/(?:\A|\r\n)Content-Disposition:([^\r\n]*)/i)
        raise InvalidRequestBody unless dispositions.length == 1

        names = dispositions.first.first.scan(/(?:\A|;)\s*name=(?:"((?:\\.|[^"])*)"|([^;\s]+))/i)
        raise InvalidRequestBody unless names.length == 1

        quoted_name = names.first.first
        if quoted_name && quoted_name.match?(/\\(?!["\\])/)
          raise InvalidRequestBody
        end
      end

      def parse_multipart(env, body)
        request_env = env.dup
        request_env.delete_if { |key, _| key.start_with?('rack.request.') }
        request_env[REQUEST_BODY] = StringIO.new(body)
        request_env['CONTENT_LENGTH'.freeze] = body.bytesize.to_s
        Rack::Request.new(request_env).POST
      rescue ArgumentError
        raise InvalidRequestBody
      end

      def cache_multipart_params(env, params)
        env['rack.request.form_hash'.freeze] = params
        env['rack.request.form_input'.freeze] = env[REQUEST_BODY]
      end

      def compatible_parameter_shapes?(left, right)
        common_keys = left.keys & right.keys
        common_keys.all? do |key|
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

      def read_body(env, length = nil)
        input = env[REQUEST_BODY]
        body = length ? input.read(length) : input.read
        body ||= ''
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

      def form_request?(env)
        media_type(env).casecmp('application/x-www-form-urlencoded') == 0
      end

      def multipart_request?(env)
        media_type(env).casecmp('multipart/form-data') == 0
      end

      def media_type(env)
        env[CONTENT_TYPE].to_s.split(';', 2).first.to_s.strip
      end

      def import_request?(env)
        env[PATH_INFO].to_s.match?(%r{\A/import/?\z})
      end

      def invalid_request_response
        error = ErrorResponse::ERRORS.fetch(:request_invalid)
        body = Typecast.to_json(error.as_json)
        [error.http_status, {Rack::CONTENT_TYPE => Api::CONTENT_TYPE}, [body]]
      end

      # Rails 3.2.2.1 Rack version does not have Rack::Request#update_param
      # Rack 1.5.0 adds update_param
      # This method accomplishes similar functionality
      def update_params(env, data)
        return if data.empty?
        parsed_request_body = Typecast.from_json(data)
        raise InvalidRequestBody unless parsed_request_body.is_a?(Hash)
        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(parsed_request_body)

        env["parsed_request_body".freeze] = parsed_request_body
        parsed_query_string = parse_query(env[QUERY_STRING].to_s)
        parsed_query_string.merge!(parsed_request_body)
        parameters = build_query(parsed_query_string)
        env[QUERY_STRING] = parameters
      rescue *ParameterParsing.errors
        raise InvalidRequestBody
      end
    end
  end
end
