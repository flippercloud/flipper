module Flipper
  class Configuration
    # Public: A name of the key in the rack environment for the current Flipper instance (default: 'flipper')
    attr_accessor :env_key

    # Public: A boolean to determine if memoization should be enabled (default: true)
    attr_accessor :memoize

    # Public: A lambda to determine if memoization should be skipped for a request
    attr_accessor :memoize_unless

    # Public: An array of feature names or boolean to preload all for each request (default: true)
    attr_accessor :preload

    def initialize(options = {})
      @default = -> { Flipper.new(Flipper::Adapters::Memory.new) }
      @env_key = options.fetch(:env_key, 'flipper')
      @memoize = options.fetch(:memoize, true)
      @preload = options.fetch(:preload, true)
    end

    # Controls the default instance for flipper. When used with a block it
    # assigns a new default block to use to generate an instance. When used
    # without a block, it performs a block invocation and returns the result.
    #
    #   configuration = Flipper::Configuration.new
    #   configuration.default # => Flipper::DSL instance using Memory adapter
    #
    #   # sets the default block to generate a new instance using ActiveRecord adapter
    #   configuration.default do
    #     require "flipper-active_record"
    #     Flipper.new(Flipper::Adapters::ActiveRecord.new)
    #   end
    #
    #   configuration.default # => Flipper::DSL instance using ActiveRecord adapter
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
