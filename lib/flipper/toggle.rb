module Flipper
  class Toggle
    def initialize(adapter, key)
      @adapter = adapter
      @key = key
    end

    def enable(thing)
      raise 'Not implemented'
    end

    def disable(thing)
      raise 'Not implemented'
    end

    def value
      raise 'Not implemented'
    end
  end
end

require 'flipper/toggles/set'
require 'flipper/toggles/value'
