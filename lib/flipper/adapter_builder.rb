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
    def initialize(default_store = Adapters::Memory, &block)
      @stack = []
      store default_store
      instance_eval(&block) if block
    end

    def use(klass, *args, **kwargs)
      @stack.push ->(adapter) { klass.new(adapter, *args, **kwargs) }
    end

    def store(adapter, *args, **kwargs)
      @store = adapter.respond_to?(:call) ? adapter : -> { adapter.new(*args, **kwargs) }
    end

    def to_adapter
      @stack.reverse.inject(@store.call) { |adapter, wrapper| wrapper.call(adapter) }
    end
  end
end
