module Flipper
  class FeatureCheckContext
    attr_reader :feature_name
    attr_reader :values

    def initialize(feature_name:, values:)
      @feature_name = feature_name
      @values = values
    end
  end
end
