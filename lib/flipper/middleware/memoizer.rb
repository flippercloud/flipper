module Flipper
  module Middleware
    class Memoizer
      # Public: Initializes an instance of the Memoizer middleware. Flipper must
      # be configured with a default instance or the flipper instance must be
      # setup in the env of the request. You can do this by using the
      # Flipper::Middleware::SetupEnv middleware.
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
          raise 'Flipper::Middleware::Memoizer no longer initializes with a flipper instance or block. Read more at: https://git.io/vSo31.'
        end

        @app = app
        @opts = opts
        @env_key = opts.fetch(:env_key, 'flipper')
      end

      def call(env)
        request = Rack::Request.new(env)

        if skip_memoize?(request)
          @app.call(env)
        else
          memoized_call(env)
        end
      end

      private

      def skip_memoize?(request)
        @opts[:unless] && @opts[:unless].call(request)
      end

      def memoized_call(env)
        reset_on_body_close = false
        flipper = env.fetch(@env_key) { Flipper }
        original = flipper.memoizing?
        flipper.memoize = true

        flipper.preload_all if @opts[:preload_all]

        if (preload = @opts[:preload])
          flipper.preload(preload)
        end

        response = @app.call(env)
        response[2] = Rack::BodyProxy.new(response[2]) do
          flipper.memoize = original
        end
        reset_on_body_close = true
        response
      ensure
        flipper.memoize = original if flipper && !reset_on_body_close
      end
    end
  end
end
