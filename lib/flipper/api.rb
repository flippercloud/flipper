require 'rack'
require 'flipper'
require 'flipper/middleware/setup_env'
require 'flipper/api/middleware'
require 'flipper/api/json_params'
require 'flipper/api/actor'

module Flipper
  module Api
    CONTENT_TYPE = 'application/json'.freeze

    def self.app(flipper = nil)
      app = ->(_) { [404, { 'Content-Type'.freeze => CONTENT_TYPE }, ['{}'.freeze]] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Middleware::SetupEnv, flipper
      builder.use Flipper::Middleware::Memoizer
      builder.use Flipper::Api::JsonParams
      builder.use Flipper::Api::Middleware
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      builder
    end
  end
end
