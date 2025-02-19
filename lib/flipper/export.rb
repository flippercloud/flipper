module Flipper
  class Export
    attr_reader :contents, :format, :version

    def initialize(contents:, format: :json, version: 1)
      @contents = contents
      @format = format
      @version = version
    end

    def features
      raise NotImplementedError
    end

    def adapter
      @adapter ||= Flipper::Adapters::Memory.new(features)
    end

    def eql?(other)
      self.class.eql?(other.class) && @contents == other.contents && @format == other.format && @version == other.version
    end
    alias_method :==, :eql?
  end
end
