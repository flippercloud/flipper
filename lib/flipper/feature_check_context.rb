module Flipper
  class FeatureCheckContext
    # Public: The name of the feature.
    attr_reader :feature_name

    # Public: The GateValues instance that keeps track of the values for the
    # gates for the feature.
    attr_reader :values

    # Public: The actors we want to know if a feature is enabled for.
    attr_reader :actors

    # The feature is passed whole (one keyword) rather than its resolvers
    # (three keywords) because this is built on every enabled? check.
    def initialize(feature_name:, values:, actors:, feature: nil)
      @feature_name = feature_name
      @values = values
      @actors = actors
      @feature = feature
    end

    # Internal: Resolves group names for the instance that owns the feature.
    def group_resolver
      @feature ? @feature.group_resolver : Flipper
    end

    # Internal: Resolver used by expressions that reference another feature.
    def feature_resolver
      @feature ? @feature.feature_resolver : Flipper
    end

    # Internal: Identity used to isolate circular expression tracking.
    def instance_key
      @feature ? @feature.instance_key : nil
    end

    def actors?
      !@actors.nil? && !@actors.empty?
    end

    # Public: Convenience method for groups value like Feature has.
    def groups_value
      values.groups
    end

    # Public: Convenience method for actors value value like Feature has.
    def actors_value
      values.actors
    end

    # Public: Convenience method for boolean value value like Feature has.
    def boolean_value
      values.boolean
    end

    # Public: Convenience method for percentage of actors value like Feature has.
    def percentage_of_actors_value
      values.percentage_of_actors
    end

    # Public: Convenience method for percentage of time value like Feature has.
    def percentage_of_time_value
      values.percentage_of_time
    end
  end
end
