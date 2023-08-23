require 'forwardable'
require 'flipper/api/error'
require 'flipper/api/error_response'
require 'json'

module Flipper
  module Api
    class Action
      module FeatureNameFromRoute
        def feature_name
          @feature_name ||= begin
            match = request.path_info.match(self.class.route_regex)
            match ? Rack::Utils.unescape(match[:feature_name]) : nil
          end
        end
        private :feature_name
      end

      extend Forwardable

      VALID_REQUEST_METHOD_NAMES = Set.new([
                                             'get'.freeze,
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
        @headers = { 'content-type' => Api::CONTENT_TYPE }
      end

      # Public: Runs the request method for the provided request.
      #
      # Returns whatever the request method returns in the action.
      def run
        if valid_request_method? && respond_to?(request_method_name)
          catch(:halt) { send(request_method_name) }
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
        header 'content-type', Api::CONTENT_TYPE
        status(status)
        body = JSON.dump(object)
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

      # Private: Returns the request method converted to an action method.
      def request_method_name
        @request_method_name ||= @request.request_method.downcase
      end

      # Private: split request path by "/"
      # Example: "features/feature_name" => ['features', 'feature_name']
      def path_parts
        @request.path.split('/')
      end

      def valid_request_method?
        VALID_REQUEST_METHOD_NAMES.include?(request_method_name)
      end
    end
  end
end
