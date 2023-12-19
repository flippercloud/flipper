module Flipper
  # Builds an adapter from a stack of adapters.
  #
  #   adapter = Flipper::AdapterBuilder.new do
  #     use Flipper::Adapters::Strict
  #     use Flipper::Adapters::Memoizer
  #     store Flipper::Adapters::Memory
  #   end.to_adapter
  #
  class AdapterBuilder
    def initialize(&block)
      @stack = []

      # Default to memory adapter
      store Flipper::Adapters::Memory

      block.arity == 0 ? instance_eval(&block) : block.call(self) if block
    end

    def use(klass, *args, **kwargs, &block)
      @stack.push ->(adapter) { klass.new(adapter, *args, **kwargs, &block) }
    end

    def store(adapter, *args, **kwargs, &block)
      @store = adapter.respond_to?(:call) ? adapter : -> { adapter.new(*args, **kwargs, &block) }
    end

    def to_adapter
      @stack.reverse.inject(@store.call) { |adapter, wrapper| wrapper.call(adapter) }
    end
  end
end
