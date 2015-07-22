module Flipper
  class GateContext
    attr_reader :gates
    attr_reader :values
    attr_reader :feature_name

    def initialize(gates:, values:, feature_name:)
      @gates = gates
      @values = values
      @feature_name = feature_name
    end
  end
end
