module Flipper
  class FeatureCheckContext
    # Public: The name of the feature.
    attr_reader :feature_name

    # Public: The GateValues instance that keeps track of the values for the
    # gates for the feature.
    attr_reader :values

    # Public: The thing we want to know if a feature is enabled for.
    attr_reader :thing

    def initialize(options = {})
      @feature_name = options.fetch(:feature_name)
      @values = options.fetch(:values)
      @thing = options.fetch(:thing)
    end
  end
end
