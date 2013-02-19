require 'rack/body_proxy'

module Flipper
  module Middleware
    class Memoizer
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
