require 'rack/body_proxy'

module Flipper
  module Middleware
    class Memoizer
      # Public: Initializes an instance of the Memoizer middleware.
      #
      # app - The app this middleware is included in.
      # flipper_or_block - The Flipper::DSL instance or a block that yields a
      #                    Flipper::DSL instance to use for all operations.
      #
      # Examples
      #
      #   # using with a normal flipper instance
      #   flipper = Flipper.new(...)
      #   use Flipper::Middleware::Memoizer, flipper
      #
      #   # using with a block that yields a flipper instance
      #   use Flipper::Middleware::Memoizer, lambda { Flipper.new(...) }
      #
      #   # using with preload_all features
      #   use Flipper::Middleware::Memoizer, flipper, preload_all: true
      #
      #   # using with preload specific features
      #   use Flipper::Middleware::Memoizer, flipper, preload: [:stats, :search, :some_feature]
      #
      def initialize(app, flipper_or_block, opts = {})
        @app = app
        @opts = opts

        if flipper_or_block.respond_to?(:call)
          @flipper_block = flipper_or_block
        else
          @flipper = flipper_or_block
        end
      end

      def flipper
        @flipper ||= @flipper_block.call
      end

      def call(env)
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
