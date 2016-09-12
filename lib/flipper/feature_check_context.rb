module Flipper
  class FeatureCheckContext
    # Public: The name of the feature.
    attr_reader :feature_name

    # Public: The GateValues instance that keeps track of the values for the
    # gates for the feature.
    attr_reader :values

    def initialize(feature_name:, values:)
      @feature_name = feature_name
      @values = values
    end
  end
end
