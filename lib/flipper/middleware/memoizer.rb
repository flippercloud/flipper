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
      #        :preload - Boolean to preload all features or Array of Symbol feature names to preload.
      #
      # Examples
      #
      #   use Flipper::Middleware::Memoizer
      #
      #   # using with preload_all features
      #   use Flipper::Middleware::Memoizer, preload: true
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

        if memoize?(request)
          memoized_call(env)
        else
          @app.call(env)
        end
      end

      private

      def memoize?(request)
        if @opts[:if]
          @opts[:if].call(request)
        elsif @opts[:unless]
          !@opts[:unless].call(request)
        else
          true
        end
      end

      def memoized_call(env)
        flipper = env.fetch(@env_key) { Flipper }

        flipper.memoize preload: @opts[:preload] do |memoized|
          Flipper.with_instance memoized do
            @app.call env.merge(@env_key => memoized)
          end
        end
      end
    end
  end
end
