module Flipper
  # Iterate over a stack of nested adapters
  #
  # Example:
  #   AdapterStack.new(Flipper.adapter).any?(Flipper::Adapters::Memory)
  class AdapterStack
    include Enumerable

    def initialize(adapter)
      @adapter = adapter
    end

    def each(&block)
      descend(@adapter, &block)
    end

    def find(pattern = nil, &block)
      block ||= ->(a) { pattern === a } if pattern
      super &block
    end

    private

    def descend(adapter, &block)
      block.call(adapter)
      adapter.adapters.each do |adapter|
        descend(adapter, &block)
      end
    end
  end
end
