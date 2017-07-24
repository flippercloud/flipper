module Flipper
  class Configuration
    def initialize
      @default = lambda do
        require "flipper/adapters/memory"
        Flipper.new Flipper::Adapters::Memory.new
      end
    end

    def default(&block)
      @default = block
    end

    def default_instance
      @default.call
    end
  end
end
