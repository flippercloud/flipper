# frozen_string_literal: true

require 'rack'
require 'flipper'
require 'flipper/api/middleware'
require 'flipper/api/json_params'

module Flipper
  module Api
    CONTENT_TYPE = 'application/json'

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      app = ->(_) { [404, { 'Content-Type' => CONTENT_TYPE }, ['{}']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Api::JsonParams
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Middleware::Memoizer, env_key: env_key
      builder.use Flipper::Api::Middleware, env_key: env_key
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      builder
    end
  end
end
