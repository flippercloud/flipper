require 'rack'
require 'flipper'
require 'flipper/api/middleware'
require 'flipper/api/json_params'
require 'flipper/api/configuration'

module Flipper
  module Api
    CONTENT_TYPE = 'application/json'.freeze

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      app = ->(_) { [404, { 'Content-Type'.freeze => CONTENT_TYPE }, ['{}'.freeze]] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Api::JsonParams
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Api::Middleware, env_key: env_key
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      builder
    end

    def self.configure
      yield(configuration)
    end

    def self.configuration
      @configuration ||= ::Flipper::Api::Configuration.new
    end
  end
end
