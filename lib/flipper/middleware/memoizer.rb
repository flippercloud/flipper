require 'rack/body_proxy'

module Flipper
  module Middleware
    class Memoizer
      # Public: Initializes an instance of the Memoizer middleware. The flipper
      # instance must be setup in the env of the request. You can do this by
      # using the Flipper::Middleware::SetupEnv middleware.
      #
      # app - The app this middleware is included in.
      # opts - The Hash of options.
      #        :preload_all - Boolean of whether or not to preload all features.
      #        :preload - Array of Symbol feature names to preload.
      #
      # Examples
      #
      #   use Flipper::Middleware::Memoizer
      #
      #   # using with preload_all features
      #   use Flipper::Middleware::Memoizer, preload_all: true
      #
      #   # using with preload specific features
      #   use Flipper::Middleware::Memoizer, preload: [:stats, :search, :some_feature]
      #
      def initialize(app, opts = {})
        if opts.is_a?(Flipper::DSL) || opts.is_a?(Proc)
          raise 'Flipper::Middleware::Memoizer no longer initializes with a \
                flipper instance or block. Read more at: https://git.io/vSo31.'
        end

        @app = app
        @opts = opts
      end

      def call(env)
        flipper = env.fetch('flipper')
        original = flipper.adapter.memoizing?
        flipper.adapter.memoize = true

        if @opts[:preload_all]
          names = flipper.features.map(&:name)
          flipper.preload(names)
        end

        flipper.preload(@opts[:preload]) if @opts[:preload]

        response = @app.call(env)
        response[2] = Rack::BodyProxy.new(response[2]) do
          flipper.adapter.memoize = original
        end
        response
      rescue
        flipper.adapter.memoize = original
        raise
      end
    end
  end
end
