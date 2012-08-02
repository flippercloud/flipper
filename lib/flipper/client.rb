module Flipper
  class Client
    def initialize(adapter)
      @adapter = adapter
    end

    def enabled?(name, *args)
      feature(name).enabled?(*args)
    end

    def disabled?(name, *args)
      !enabled?(name, *args)
    end

    def enable(name, *args)
      feature(name).enable(*args)
    end

    def disable(name, *args)
      feature(name).disable(*args)
    end

    def feature(name)
      features[name.to_sym] ||= Flipper::Feature.new(name, @adapter)
    end

    def group(name)
      Flipper.group(name)
    end

    private

    def features
      @features ||= {}
    end
  end
end
