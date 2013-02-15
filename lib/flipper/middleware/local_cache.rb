require 'rack/body_proxy'

module Flipper
  module Middleware
    class LocalCache
      def initialize(app, flipper)
        @app = app
        @flipper = flipper
      end

      def call(env)
        original = @flipper.adapter.memoizing?
        @flipper.adapter.memoize = true

        response = @app.call(env)
        response[2] = Rack::BodyProxy.new(response[2]) {
          @flipper.adapter.memoize = original
        }
        response
      end
    end
  end
end
