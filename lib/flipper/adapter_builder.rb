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

    def use(klass, *args, &block)
      @stack.push ->(adapter) { klass.new(adapter, *args, &block) }
    end

    def store(adapter, *args, &block)
      @store = adapter.respond_to?(:call) ? adapter : -> { adapter.new(*args, &block) }
    end

    def to_adapter
      @stack.reverse.inject(@store.call) { |adapter, wrapper| wrapper.call(adapter) }
    end

    # Properly pass kwargs to `use` and `store` methods.
    # Replace with `...` once support for Ruby 2.6 and 2.7 are dropped
    if respond_to?(:ruby2_keywords, true)
      ruby2_keywords :use
      ruby2_keywords :store
    end
  end
end
