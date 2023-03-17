module Flipper
  class Export
    attr_reader :input, :format, :version

    def initialize(input:, format: :json, version: 1)
      @input = input
      @format = format
      @version = version
    end

    def eql?(other)
      self.class.eql?(other.class) && @input == other.input && @format == other.format && @version == other.version
    end
    alias_method :==, :eql?
  end
end
