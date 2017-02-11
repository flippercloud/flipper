require 'rack'
require 'flipper'
require 'flipper/api/middleware'
require 'flipper/api/json_params'
require 'flipper/api/setup_env'
require 'flipper/api/actor'

module Flipper
  module Api
    CONTENT_TYPE = 'application/json'.freeze

    def self.app(flipper = nil)
      app = App.new(200, { 'Content-Type' => CONTENT_TYPE }, [''])
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Api::SetupEnv, flipper
      builder.use Flipper::Api::JsonParams
      builder.use Flipper::Api::Middleware
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
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
      def call(_env)
        response
      end

      private

      def response
        [@status, @headers, @body]
      end
    end
  end
end
