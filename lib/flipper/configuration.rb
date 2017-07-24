module Flipper
  class Configuration
    def initialize
      @default = lambda { raise DefaultNotSet }
    end

    def default(&block)
      @default = block
    end

    def default_instance
      @default.call
    end
  end
end
