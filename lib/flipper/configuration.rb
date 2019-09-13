module Flipper
  class Configuration
    def initialize
      @default = -> { raise DefaultNotSet }
    end

    # Controls the default instance for flipper. When used with a block it
    # assigns a new default block to use to generate an instance. When used
    # without a block, it performs a block invocation and returns the result.
    #
    #   configuration = Flipper::Configuration.new
    #   configuration.default # => raises DefaultNotSet error.
    #
    #   # sets the default block to generate a new instance using Memory adapter
    #   configuration.default do
    #     require "flipper/adapters/memory"
    #     Flipper.new(Flipper::Adapters::Memory.new)
    #   end
    #
    #   configuration.default # => Flipper::DSL instance using Memory adapter
    #
    # Returns result of default block invocation if called without block. If
    # called with block, assigns the default block.
    def default(&block)
      if block_given?
        @default = block
      else
        @default.call
      end
    end
  end
end
