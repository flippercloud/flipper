module Flipper
  class Error < StandardError; end

  class GateNotFound < Error
    def initialize(thing)
      super "Could not find gate for #{thing.inspect}"
    end
  end

  class DuplicateGroup < Error; end
end
