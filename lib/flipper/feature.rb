require 'adapter'

module Flipper
  class Feature
    def initialize(name, adapter)
      @name = name
      @adapter = adapter
    end

    def enable
      @adapter.write(boolean_key(@name), true)
    end

    def disable
      @adapter.write(boolean_key(@name), false)
    end

    def enabled?
      @adapter.read(boolean_key(@name)) == true
    end

    def disabled?
      !enabled?
    end

    private

    def boolean_key(name)
      "#{name}_boolean"
    end
  end
end
