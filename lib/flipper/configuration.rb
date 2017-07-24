module Flipper
  class Configuration
    def initialize
      @default = lambda { raise DefaultNotSet }
    end

    # Controls the default instance for flipper. Defaults to raising an error.
    #
    # Flipper::Configuration.new.default do
    #   require "flipper/adapters/memory"
    #   Flipper.new(Flipper::Adapters::Memory.new)
    # end
    def default(&block)
      @default = block
    end

    # Public: Returns the result of default block invocation, which should
    # always be a Flipper::DSL instance. This can be set with default method.
    def default_instance
      @default.call
    end
  end
end
