module Flipper
  module Adapters
    # A base class for any adapter that wraps another adapter. By default, all methods
    # delegate to the wrapped adapter. Implement `#wrap` to customize the behavior of
    # all delegated methods, or override individual methods as needed.
    class Wrapper
      include Flipper::Adapter

      METHODS = [
        :import,
        :export,
        :features,
        :add,
        :remove,
        :clear,
        :get,
        :get_multi,
        :get_all,
        :enable,
        :disable,
      ].freeze

      attr_reader :adapter

      def initialize(adapter)
        @adapter = adapter
      end

      METHODS.each do |method|
        if RUBY_VERSION >= '3.0'
          define_method(method) do |*args, **kwargs|
            wrap(method, *args, **kwargs) { @adapter.public_send(method, *args, **kwargs) }
          end
        else
          define_method(method) do |*args|
            wrap(method, *args) { @adapter.public_send(method, *args) }
          end
        end
      end

      # Override this method to customize the behavior of all delegated methods, and just yield to
      # the block to call the wrapped adapter.
      if RUBY_VERSION >= '3.0'
        def wrap(method, *args, **kwargs, &block)
          block.call
        end
      else
        def wrap(method, *args, &block)
          block.call
        end
      end
    end
  end
end
