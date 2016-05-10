module Flipper
  module Api
    class Action
      extend Forwardable

      # Public: Call this in subclasses so the action knows its route.
      #
      # regex - The Regexp that this action should run for.
      #
      # Returns nothing.
      def self.route(regex)
        @regex = regex
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

      # Internal: The regex that matches which routes this action will work for.
      def self.regex
        @regex || raise("#{name}.route is not set")
      end

      # Public: The instance of the Flipper::DSL the middleware was
      # initialized with.
      attr_reader :flipper

      # Public: The Rack::Request to provide a response for.
      attr_reader :request

      # Public: The params for the request.
      def_delegator :@request, :params

      def initialize(flipper, request)
        @flipper, @request = flipper, request
        @code = 200
        @headers = {"Content-Type" => Api::CONTENT_TYPE }
      end

      # Public: Runs the request method for the provided request.
      #
      # Returns whatever the request method returns in the action.
      def run
        if respond_to?(request_method_name)
          catch(:halt) { send(request_method_name) }
        else
          raise Api::RequestMethodNotSupported, "#{self.class} does not support request method #{request_method_name.inspect}"
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

      def json_response(object, status = 200)
        header 'Content-Type', Api::CONTENT_TYPE
        status(status)
        body = JSON.dump(object)
        halt [@code, @headers, [body]]
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
      # Example: "api/v1/features/feature_name" => ['api', 'v1', 'features', 'feature_name']
      def path_parts
        @request.path.split("/")
      end
    end
  end
end
