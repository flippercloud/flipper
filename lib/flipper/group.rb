module Flipper
  class Group
    attr_reader :name

    def initialize(name, &block)
      @name = name.to_sym
      @block = block
    end

    def match?(*args)
      @block.call(*args) == true
    end
  end
end
