require 'rack/utils'

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

      # Public: Merge request body params with query string params
      # This way can access all params with Rack::Request#params
      # Rack does not add application/json params to Rack::Request#params
      # Allows app to handle x-www-url-form-encoded / application/json request
      # parameters the same way
      def call(env)
        if env[CONTENT_TYPE] == 'application/json'
          body = env[REQUEST_BODY].read
          env[REQUEST_BODY].rewind
          update_params(env, body)
        end
        @app.call(env)
      end

      private

      # Rails 3.2.2.1 Rack version does not have Rack::Request#update_param
      # Rack 1.5.0 adds update_param
      # This method accomplishes similar functionality
      def update_params(env, data)
        return if data.empty?
        parsed_request_body = Typecast.from_json(data)
        env["parsed_request_body".freeze] = parsed_request_body
        parsed_query_string = parse_query(env[QUERY_STRING])
        parsed_query_string.merge!(parsed_request_body)
        parameters = build_query(parsed_query_string)
        env[QUERY_STRING] = parameters
      end
    end
  end
end
