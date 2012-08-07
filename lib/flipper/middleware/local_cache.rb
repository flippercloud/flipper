module Flipper
  module Middleware
    class LocalCache
      class Body
        def initialize(target, flipper, original)
          @target   = target
          @flipper  = flipper
          @original = original
        end

        def each(&block)
          @target.each(&block)
        end

        def close
          @target.close if @target.respond_to?(:close)
        ensure
          @flipper.adapter.use_local_cache = @original
        end
      end

      def initialize(app, flipper)
        @app = app
        @flipper = flipper
      end

      def call(env)
        original = @flipper.adapter.using_local_cache?
        @flipper.adapter.use_local_cache = true

        status, headers, body = @app.call(env)
        [status, headers, Body.new(body, @flipper, original)]
      end
    end
  end
end
