require 'rack/body_proxy'

module Flipper
  module Middleware
    class Memoizer
      # Public: Initializes an instance of the UI middleware.
      #
      # app - The app this middleware is included in.
      # flipper_or_block - The Flipper::DSL instance or a block that yields a
      #                    Flipper::DSL instance to use for all operations.
      #
      # Examples
      #
      #   flipper = Flipper.new(...)
      #
      #   # using with a normal flipper instance
      #   use Flipper::Middleware::Memoizer, flipper
      #
      #   # using with a block that yields a flipper instance
      #   use Flipper::Middleware::Memoizer, lambda { Flipper.new(...) }
      #
      def initialize(app, flipper_or_block)
        @app = app

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

        response = @app.call(env)
        response[2] = Rack::BodyProxy.new(response[2]) {
          flipper.adapter.memoize = original
        }
        response
      end
    end
  end
end
