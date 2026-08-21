require 'forwardable'
require 'set'
require 'flipper/api/error'
require 'flipper/api/error_response'
require 'flipper/api/parameter_parsing'
require 'json'

module Flipper
  module Api
    class Action
      module FeatureNameFromRoute
        def feature_name
          @feature_name ||= begin
            match = request.path_info.match(self.class.route_regex)
            if match
              value = Rack::Utils.unescape(match[:feature_name])
              json_error_response(:request_invalid) unless value.valid_encoding?
              value
            end
          end
        rescue ArgumentError
          json_error_response(:request_invalid)
        end
        private :feature_name
      end

      extend Forwardable

      VALID_REQUEST_METHOD_NAMES = Set.new([
                                             'head'.freeze,
                                             'get'.freeze,
                                             'post'.freeze,
                                             'put'.freeze,
                                             'delete'.freeze,
                                           ]).freeze
      MUTATION_REQUEST_METHOD_NAMES = Set.new([
                                                'post'.freeze,
                                                'put'.freeze,
                                                'delete'.freeze,
                                              ]).freeze

      # Public: Call this in subclasses so the action knows its route.
      #
      # regex - The Regexp that this action should run for.
      #
      # Returns nothing.
      def self.route(regex)
        @route_regex = regex
      end

      # Internal: Does this action's route match the path.
      def self.route_match?(path)
        path.match(route_regex)
      end

      # Internal: The regex that matches which routes this action will work for.
      def self.route_regex
        @route_regex || raise("#{name}.route is not set")
      end

      # Internal: Initializes and runs an action for a given request.
      #
      # flipper - The Flipper::DSL instance.
      # request - The Rack::Request that was sent.
      #
      # Returns result of Action#run.
      def self.run(flipper, request)
        new(flipper, request).run
      end

      # Public: The instance of the Flipper::DSL the middleware was
      # initialized with.
      attr_reader :flipper

      # Public: The Rack::Request to provide a response for.
      attr_reader :request

      # Public: The params for the request.
      def_delegator :@request, :params

      def initialize(flipper, request)
        @flipper = flipper
        @request = request
        @code = 200
        @headers = {Rack::CONTENT_TYPE => Api::CONTENT_TYPE}
      end

      # Public: Runs the request method for the provided request.
      #
      # Returns whatever the request method returns in the action.
      def run
        if valid_request_method? && respond_to?(request_method_name)
          catch(:halt) do
            if mutation_request? && !json_request? && params_invalid?
              json_error_response(:request_invalid)
            end
            send(request_method_name)
          end
        else
          raise Api::RequestMethodNotSupported,
                "#{self.class} does not support request method #{request_method_name.inspect}"
        end
      end

      # Public: Runs another action from within the request method of a
      # different action.
      #
      # action_class - The class of the other action to run.
      #
      # Examples
      #
      #   run_other_action Home
      #   # => result of running Home action
      #
      # Returns result of other action.
      def run_other_action(action_class)
        action_class.new(flipper, request).run
      end

      # Public: Call this with a response to immediately stop the current action
      # and respond however you want.
      #
      # response - The response you would like to return.
      def halt(response)
        throw :halt, response
      end

      # Public: Call this with a json serializable object (i.e. Hash)
      # to serialize object and respond to request
      #
      # object - json serializable object
      # status - http status code

      def json_response(object, status = 200)
        header Rack::CONTENT_TYPE, Api::CONTENT_TYPE
        status(status)
        body = Typecast.to_json(object)
        halt [@code, @headers, [body]]
      end

      # Public: Call this with an ErrorResponse::ERRORS key to respond
      # with the serialized error object as response body
      #
      # error_key - key to lookup error object

      def json_error_response(error_key)
        error = ErrorResponse::ERRORS.fetch(error_key.to_sym)
        json_response(error.as_json, error.http_status)
      end

      # Public: Set the status code for the response.
      #
      # code - The Integer code you would like the response to return.
      def status(code)
        @code = code.to_i
      end

      # Public: Set a header.
      #
      # name - The String name of the header.
      # value - The value of the header.
      def header(name, value)
        @headers[name] = value
      end

      private

      # Private: Does a feature with this key exist?
      #
      # Reads through the memoized key set below so that checking many names
      # costs one adapter enumeration per request rather than one per name.
      def feature_exists?(feature_name)
        existing_feature_names.include?(feature_name)
      end

      # Private: The keys of every feature known to the adapter, read once per
      # request. Actions are instantiated per request (see .run), so this is
      # request scoped and cannot go stale across requests.
      def existing_feature_names
        @existing_feature_names ||= flipper.features.map(&:key).to_set
      end

      # Private: Returns request parameters, or an empty hash when Rack cannot
      # parse client-controlled parameter syntax.
      def safe_params
        @safe_params ||= params
      rescue *parameter_parser_errors
        @params_parse_failed = true
        @safe_params = {}
      rescue EOFError
        raise unless multipart_request?

        @params_parse_failed = true
        @safe_params = {}
      end

      def params_parse_failed?
        safe_params
        @params_parse_failed == true
      end

      def params_invalid?
        params_parse_failed? || !ParameterParsing.valid_encoding?(safe_params)
      end

      # Private: Returns a valid String parameter, ignoring other shapes and
      # invalid encodings.
      def string_param(name)
        return if container_param?(name)

        value = safe_params[name]
        value if valid_param_string?(value)
      end

      # Private: Returns an optional String parameter. Nil retains the legacy
      # meaning of an omitted parameter, while other non-String shapes are
      # rejected before an action can mutate state.
      def optional_string_param(name)
        json_error_response(:request_invalid) if container_param?(name)

        value = safe_params[name]
        return if value.nil?
        return value if valid_param_string?(value)

        json_error_response(:request_invalid)
      end

      def valid_param_string?(value)
        value.is_a?(String) && value.valid_encoding?
      end

      def container_param?(name)
        body_params = request.env["parsed_request_body".freeze]
        return false unless body_params.is_a?(Hash) && body_params.key?(name)

        value = body_params[name]
        value.is_a?(Array) || value.is_a?(Hash)
      end

      def parameter_parser_errors
        # Rack 2.0 uses plain RangeError for query limits. JsonParams handles
        # mutation query errors around the parser call itself before action
        # dispatch. Keep the Phase 2 fail-open behavior for read queries, but
        # do not hide body IO or application defects during mutations.
        errors = ParameterParsing.errors
        mutation_request? ? errors - [RangeError] : errors
      end

      # Private: Returns the request method converted to an action method.
      # Converts head to get.
      def request_method_name
        @request_method_name ||= begin
          name = @request.request_method.downcase
          name == "head" ? "get" : name
        end
      end

      # Private: split request path by "/"
      # Example: "features/feature_name" => ['features', 'feature_name']
      def path_parts
        @request.path.split('/')
      end

      def valid_request_method?
        VALID_REQUEST_METHOD_NAMES.include?(request_method_name)
      end

      def mutation_request?
        MUTATION_REQUEST_METHOD_NAMES.include?(request_method_name)
      end

      def json_request?
        request_media_type.casecmp('application/json') == 0
      end

      def multipart_request?
        request_media_type.casecmp('multipart/form-data') == 0
      end

      def request_media_type
        request.env['CONTENT_TYPE'.freeze].to_s.split(';', 2).first.to_s.strip
      end
    end
  end
end
