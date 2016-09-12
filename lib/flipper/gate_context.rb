module Flipper
  class GateContext
    attr_reader :values
    attr_reader :feature_name

    def initialize(values:, feature_name:)
      @values = values
      @feature_name = feature_name
    end
  end
end
