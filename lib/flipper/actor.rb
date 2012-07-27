module Flipper
  class Actor
    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def value
      @identifier
    end
  end
end
