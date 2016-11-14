require 'rack'
require 'flipper'
require 'flipper/api/middleware'
require 'flipper/api/actor'

module Flipper
  module Api
    CONTENT_TYPE = 'application/json'.freeze

    def self.app(flipper)
      app = App.new(200,{ 'Content-Type' => CONTENT_TYPE }, [''])
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Api::Middleware, flipper
      builder.run app
      builder
    end

    class App
      # Public: HTTP response code
      # Use this method to update status code before responding
      attr_writer :status

      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
      end

      # Public : Rack expects object that responds to call
      # env - environment hash
      def call(env)
        response
      end

      private

      def response
        [@status, @headers, @body]
      end
    end
  end
end
