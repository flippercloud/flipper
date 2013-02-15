require 'rack/body_proxy'

module Flipper
  module Middleware
    class LocalCache
      def initialize(app, flipper)
        @app = app
        @flipper = flipper
      end

      def call(env)
        original = @flipper.adapter.using_local_cache?
        @flipper.adapter.use_local_cache = true

        status, headers, body = @app.call(env)

        body_proxy = Rack::BodyProxy.new(body) {
          @flipper.adapter.use_local_cache = original
        }

        [status, headers, body_proxy]
      end
    end
  end
end
