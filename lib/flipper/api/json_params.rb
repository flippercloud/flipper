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
      MULTIPART_TEMPFILES = 'flipper.api.multipart_tempfiles'.freeze
      BOUNDARY_ASSIGNMENT = /(?:\A|;)[ \t]*boundary[ \t]*=/i
      BOUNDARY_PARAMETER = /(?:\A|;)[ \t]*boundary[ \t]*=[ \t]*(?:"([^"]*)"|([^; \t]+))[ \t]*(?=;|\z)/i
      VALID_MULTIPART_BOUNDARY = /\A[-0-9A-Za-z'()+_,.\/:=? ]{0,69}[-0-9A-Za-z'()+_,.\/:=?]\z/n
      VALID_UNQUOTED_MULTIPART_BOUNDARY = /\A[!#$%&'*+\-.^_`|~0-9A-Za-z]+\z/n
      InvalidRequestBody = Class.new(StandardError)
      class MultipartCallbackError < StandardError
        attr_reader :original

        def initialize(original)
          @original = original
          super(original.message)
          set_backtrace(original.backtrace)
        end
      end
      class MultipartCallbackIO
        attr_reader :original

        def initialize(original)
          @original = original
        end

        def respond_to_missing?(name, include_private = false)
          original.respond_to?(name, include_private) || super
        rescue StandardError => error
          raise MultipartCallbackError.new(error)
        end

        def method_missing(name, *args, &block)
          original.public_send(name, *args, &block)
        rescue StandardError => error
          raise MultipartCallbackError.new(error)
        end
      end
      private_constant :InvalidRequestBody
      private_constant :MultipartCallbackError
      private_constant :MultipartCallbackIO
      private_constant :MULTIPART_TEMPFILES
      private_constant :BOUNDARY_ASSIGNMENT
      private_constant :BOUNDARY_PARAMETER
      private_constant :VALID_MULTIPART_BOUNDARY
      private_constant :VALID_UNQUOTED_MULTIPART_BOUNDARY

      # Public: Merge request body params with query string params
      # This way can access all params with Rack::Request#params
      # Rack does not add application/json params to Rack::Request#params
      # Allows app to handle x-www-url-form-encoded / application/json request
      # parameters the same way
      def call(env)
        response_returned = false
        response = prepare_request(env) ? @app.call(env) : invalid_request_response
        response_returned = true
        response
      ensure
        begin
          close_multipart_tempfiles(env) unless response_returned
        ensure
          env.delete(MULTIPART_TEMPFILES)
        end
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
      rescue InvalidRequestBody
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
        if form_request?(env)
          body = normalize_form_body(body)
          cache_form_params(env, validate_form_params(env, body), form_vars: body)
        end
        validate_multipart_params(env, body) if multipart_request?(env)
        body
      end

      def validate_form_params(env, body)
        query_params = ParameterParsing.parse_nested_query(env[QUERY_STRING].to_s)
        body_params = ParameterParsing.parse_nested_query(body, '&')
        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(query_params)
        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(body_params)
        raise InvalidRequestBody unless compatible_parameter_shapes?(query_params, body_params)

        body_params
      rescue *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def normalize_form_body(body)
        body.end_with?("\0") ? body.byteslice(0, body.bytesize - 1) : body
      end

      def validate_multipart_params(env, body)
        boundary = multipart_boundary(env)
        return if body.empty?

        original, reversed, empty = normalized_multipart_bodies(body, boundary)
        body_params = if empty
          {}
        else
          parse_multipart(env, original, boundary: boundary, use_application_factory: true)
        end
        if reversed
          parse_multipart(env, reversed, boundary: boundary, use_application_factory: false)
        end
        query_params = ParameterParsing.parse_nested_query(env[QUERY_STRING].to_s)

        raise InvalidRequestBody unless ParameterParsing.valid_encoding?(body_params)
        raise InvalidRequestBody unless compatible_parameter_shapes?(query_params, body_params)
        cache_multipart_params(env, body_params)
      rescue MultipartCallbackError => error
        raise error.original
      rescue EOFError, *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def multipart_boundary(env)
        content_type = env[CONTENT_TYPE].to_s
        assignments = content_type.scan(BOUNDARY_ASSIGNMENT)
        matches = content_type.scan(BOUNDARY_PARAMETER)
        raise InvalidRequestBody unless assignments.length == 1 && matches.length == 1

        quoted, unquoted = matches.first
        boundary = quoted || unquoted
        binary_boundary = boundary.dup.force_encoding(Encoding::BINARY)
        if unquoted
          raise InvalidRequestBody unless VALID_UNQUOTED_MULTIPART_BOUNDARY.match?(binary_boundary)
        end
        raise InvalidRequestBody if boundary.bytesize > 70
        raise InvalidRequestBody unless VALID_MULTIPART_BOUNDARY.match?(binary_boundary)

        boundary
      end

      def normalized_multipart_bodies(body, boundary)
        delimiters = multipart_delimiters(body, boundary)
        raise InvalidRequestBody if delimiters.empty?
        raise InvalidRequestBody unless delimiters.last[2]
        return [body, nil, true] if delimiters.first[2]

        parts = delimiters.each_cons(2).map do |left, right|
          body.byteslice(left[1], right[0] - left[1])
        end
        parts.each { |part| validate_multipart_part!(part) }

        preamble = body.byteslice(0, delimiters.first[0])
        opening_prefix = body.byteslice(delimiters.first[0], 2) == "\r\n" ? "\r\n" : ""
        epilogue = body.byteslice(delimiters.last[1], body.bytesize - delimiters.last[1])
        separator = "\r\n--#{boundary}\r\n"
        original = "#{preamble}#{opening_prefix}--#{boundary}\r\n" \
          "#{parts.join(separator)}\r\n--#{boundary}--\r\n#{epilogue}"
        reversed = if parts.length > 1
          "#{preamble}#{opening_prefix}--#{boundary}\r\n" \
            "#{parts.reverse.join(separator)}\r\n--#{boundary}--\r\n#{epilogue}"
        end
        [original, reversed, false]
      end

      def multipart_delimiters(body, boundary)
        pattern = Regexp.new(
          "(?:\\A|\\r\\n)--#{Regexp.escape(boundary)}(--)?[ \\t]*(?:\\r\\n|\\z)",
          Regexp::NOENCODING
        )
        delimiters = []
        offset = 0
        while (match = pattern.match(body, offset))
          delimiters << [match.begin(0), match.end(0), !match[1].nil?]
          break if match[1]

          offset = match.end(0)
        end
        delimiters
      end

      def validate_multipart_part!(part)
        headers, separator, = part.partition("\r\n\r\n")
        raise InvalidRequestBody if separator.empty?

        unfolded_headers = headers.gsub(/\r\n[ \t]+/, ' ')
        dispositions = unfolded_headers.scan(/(?:\A|\r\n)Content-Disposition:([^\r\n]*)/i)
        raise InvalidRequestBody unless dispositions.length == 1

        disposition = dispositions.first.first
        disposition_type = disposition.split(';', 2).first.to_s.strip
        raise InvalidRequestBody unless disposition_type.casecmp('form-data') == 0

        names = disposition.scan(/(?:\A|;)\s*name=(?:"((?:\\.|[^"])*)"|([^;\s]+))/i)
        raise InvalidRequestBody unless names.length == 1

        quoted_name = names.first.first
        parameter_name = (quoted_name || names.first.last).dup.force_encoding(Encoding::UTF_8)
        raise InvalidRequestBody unless parameter_name.valid_encoding?
        if quoted_name && quoted_name.match?(/\\(?!["\\])/)
          raise InvalidRequestBody
        end
      end

      def parse_multipart(env, body, boundary:, use_application_factory:)
        request_env = env.dup
        request_env.delete_if { |key, _| key.start_with?('rack.request.') }
        request_env[REQUEST_BODY] = StringIO.new(body)
        request_env[CONTENT_TYPE] = "multipart/form-data; boundary=\"#{boundary}\""
        request_env['CONTENT_LENGTH'.freeze] = body.bytesize.to_s
        if use_application_factory
          tempfiles = env[MULTIPART_TEMPFILES] ||= []
          registered_tempfiles = env['rack.tempfiles'.freeze] ||= []
        else
          tempfiles = []
          registered_tempfiles = tempfiles
        end
        prepare_multipart_factory(
          request_env,
          use_application_factory,
          tempfiles,
          registered_tempfiles
        )
        params = Rack::Request.new(request_env).POST
        unwrap_multipart_callback_ios(params)
      ensure
        tempfiles.each(&:close) if tempfiles && !use_application_factory
      end

      def prepare_multipart_factory(env, use_application_factory, tempfiles, registered_tempfiles)
        if use_application_factory
          factory = env['rack.multipart.tempfile_factory'.freeze] ||
            Rack::Multipart::Parser::TEMPFILE_FACTORY

          env['rack.multipart.tempfile_factory'.freeze] = lambda do |*args, **kwargs|
            io = factory.call(*args, **kwargs)
            tempfiles << io
            registered_tempfiles << io unless registered_tempfiles.equal?(tempfiles)
            MultipartCallbackIO.new(io)
          rescue StandardError => error
            raise MultipartCallbackError.new(error)
          end
        else
          env['rack.multipart.tempfile_factory'.freeze] = lambda do |*, **|
            io = StringIO.new
            tempfiles << io
            io
          end
        end
      end

      def close_multipart_tempfiles(env)
        tempfiles = env[MULTIPART_TEMPFILES]
        return unless tempfiles

        active_error = $!
        cleanup_error = nil
        registered_tempfiles = env['rack.tempfiles'.freeze]
        tempfiles.each do |tempfile|
          begin
            if tempfile.respond_to?(:close!)
              tempfile.close!
            elsif tempfile.respond_to?(:close)
              tempfile.close
            end
          rescue StandardError => error
            cleanup_error ||= error
          ensure
            registered_tempfiles.delete(tempfile) if registered_tempfiles
          end
        end
        raise cleanup_error if cleanup_error && active_error.nil?
      end

      def unwrap_multipart_callback_ios(value)
        case value
        when Hash
          value.each { |key, item| value[key] = unwrap_multipart_callback_ios(item) }
        when Array
          value.map! { |item| unwrap_multipart_callback_ios(item) }
        when MultipartCallbackIO
          value.original
        else
          value
        end
      end

      def cache_multipart_params(env, params)
        cache_form_params(env, params)
      end

      def cache_form_params(env, params, form_vars: nil)
        env['rack.request.form_hash'.freeze] = params
        env['rack.request.form_input'.freeze] = env[REQUEST_BODY]
        env['rack.request.form_vars'.freeze] = form_vars unless form_vars.nil?
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
        body = length ? ParameterParsing.read_bounded(input, length) : input.read
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
        parsed_request_body = parse_json_body(data)
        raise InvalidRequestBody unless parsed_request_body.is_a?(Hash)
        raise InvalidRequestBody unless ParameterParsing.valid_json?(parsed_request_body)

        env["parsed_request_body".freeze] = parsed_request_body
        if mutation_request?(env)
          parsed_query_shapes = ParameterParsing.parse_nested_query(env[QUERY_STRING].to_s)
          unless compatible_parameter_shapes?(parsed_query_shapes, parsed_request_body)
            raise InvalidRequestBody
          end
        end
        parsed_query_string = parse_query(env[QUERY_STRING].to_s)
        parsed_query_string.merge!(parsed_request_body)
        parameters = build_query(parsed_query_string)
        env[QUERY_STRING] = parameters
      rescue *ParameterParsing.errors
        raise InvalidRequestBody
      end

      def parse_json_body(data)
        ParameterParsing.parse_json(data)
      rescue JSON::ParserError
        raise InvalidRequestBody
      end
    end
  end
end
