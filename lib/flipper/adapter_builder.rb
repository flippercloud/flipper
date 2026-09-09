module Flipper
  # Builds an adapter from a stack of adapters.
  #
  #   adapter = Flipper::AdapterBuilder.new do
  #     use Flipper::Adapters::Strict
  #     use Flipper::Adapters::Memoizable
  #     store Flipper::Adapters::Memory
  #   end.to_adapter
  #
  class AdapterBuilder
    def initialize(&block)
      @stack = []
      @store_wrappers = {}

      # Default to memory adapter
      store Flipper::Adapters::Memory

      block.arity == 0 ? instance_eval(&block) : block.call(self) if block
    end

    # Internal: Wraps the configured storage adapter before the adapters added
    # with #use. A key ensures framework integrations can safely configure the
    # same wrapper more than once during initialization.
    def wrap_store(key, &block)
      @store_wrappers[key] ||= block
    end

    if RUBY_VERSION >= '3.0'
      def use(klass, *args, **kwargs, &block)
        @stack.push ->(adapter) { klass.new(adapter, *args, **kwargs, &block) }
      end
    else
      def use(klass, *args, &block)
        @stack.push ->(adapter) { klass.new(adapter, *args, &block) }
      end
    end

    if RUBY_VERSION >= '3.0'
      def store(adapter, *args, **kwargs, &block)
        @store = adapter.respond_to?(:call) ? adapter : -> { adapter.new(*args, **kwargs, &block) }
      end
    else
      def store(adapter, *args, &block)
        @store = adapter.respond_to?(:call) ? adapter : -> { adapter.new(*args, &block) }
      end
    end

    def to_adapter
      store = @store_wrappers.each_value.inject(@store.call) do |adapter, wrapper|
        wrapper.call(adapter)
      end
      @stack.reverse.inject(store) { |adapter, wrapper| wrapper.call(adapter) }
    end
  end
end
