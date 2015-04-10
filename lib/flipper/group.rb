module Flipper
  class Group
    attr_reader :name

    def initialize(name, &block)
      name = name.to_sym
      if name.to_s.include?(Types::Group::SEPARATOR)
        raise ArgumentError.new("#{name.inspect} must not include #{Types::Group::SEPARATOR.inspect} characters")
      end

      @name = name
      @block = block
    end

    def match?(*args)
      @block.call(*args) == true
    end
  end
end
