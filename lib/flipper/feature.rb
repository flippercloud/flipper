module Flipper
  class Feature
    def initialize(name)
      @name = name
    end

    def enable
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def enabled?
      @enabled == true
    end

    def disabled?
      !enabled?
    end
  end
end
