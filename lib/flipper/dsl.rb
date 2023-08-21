require 'forwardable'

module Flipper
  class DSL
    extend Forwardable

    # @internal
    attr_reader :adapter

    # @internal What is being used to instrument all the things.
    attr_reader :instrumenter

    # @internal
    def_delegators :@adapter, :memoize=, :memoizing?, :import, :export

    # Creates a new instance of the DSL.
    #
    # @param adapter [Adapter] The adapter that this DSL instance should use.
    # @option options [#instrument] :instrumenter What should be used to instrument all the things.
    # @option options [Boolean] :memoize Should adapter be wrapped by memoize adapter or not.
    def initialize(adapter, options = {})
      @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
      memoize = options.fetch(:memoize, true)
      adapter = Adapters::Memoizable.new(adapter) if memoize
      @adapter = adapter
      @memoized_features = {}
    end

    # Check if a feature is enabled.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param args The args passed through to the enabled check.
    # @return [Boolean] true if feature is enabled, false if not.
    def enabled?(name, *args)
      feature(name).enabled?(*args)
    end

    # Enable a feature.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param args The args passed through to the feature instance enable call.
    # @return the result of {Feature#enable}
    def enable(name, *args)
      feature(name).enable(*args)
    end

    # Enable a feature for an actor.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param actor [Types::Actor, #flipper_id]
    # @return [Boolean] the result of {#enable}
    def enable_actor(name, actor)
      feature(name).enable_actor(actor)
    end

    # Enable a feature for a group.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param group [Types::Group, String, Symbol] The name of a registered group.
    # @return the result of {Feature#enable}.
    def enable_group(name, group)
      feature(name).enable_group(group)
    end

    # Enable a feature a percentage of time.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param percentage [Types::PercentageOfTime, #to_i] The percentage of time to enable the feature.
    # @return the result of {Feature#enable}.
    def enable_percentage_of_time(name, percentage)
      feature(name).enable_percentage_of_time(percentage)
    end

    # Enable a feature for a percentage of actors.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param percentage [Types::PercentageOfActors, #to_i] The percentage of actors to enable the feature.
    # @return the result of {Feature#enable}.
    def enable_percentage_of_actors(name, percentage)
      feature(name).enable_percentage_of_actors(percentage)
    end

    # Disable a feature.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param args The args passed through to {Feature#disable}
    # @return the result of {Feature#disable}
    def disable(name, *args)
      feature(name).disable(*args)
    end

    # Disable a feature for an actor.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param actor [Types::Actor, #flipper_id]
    # @return the result of {Feature#disable}
    def disable_actor(name, actor)
      feature(name).disable_actor(actor)
    end

    # Disable a feature for a group.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param group [Types::Group, String, Symbol] The name of a registered group.
    # @return the result of {Feature#disable}
    def disable_group(name, group)
      feature(name).disable_group(group)
    end

    # Disable a feature a percentage of time.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param percentage [Types::PercentageOfTime, #to_i] The percentage of time to enable the feature.
    # @return the result of {Feature#disable}
    def disable_percentage_of_time(name)
      feature(name).disable_percentage_of_time
    end

    # Disable a feature for a percentage of actors.
    #
    # @param name [String, Symbol] The name of the feature.
    # @param percentage [Types::PercentageOfActors, #to_i] The percentage of actors to enable the feature.
    # @return the result of {Feature#disable}
    def disable_percentage_of_actors(name)
      feature(name).disable_percentage_of_actors
    end

    # Add a feature.
    #
    # @param name [String, Symbol] The name of the feature.
    # @return the result of {Feature#add}
    def add(name)
      feature(name).add
    end

    # Has a feature been added in the adapter.
    #
    # @param name [String, Symbol] The name of the feature.
    # @return [Boolean] true if added else false.
    def exist?(name)
      feature(name).exist?
    end

    # Remove a feature.
    #
    # @param name [String, Symbol] The name of the feature.
    # @return the result of {Feature#remove}.
    def remove(name)
      feature(name).remove
    end

    # Access a feature instance by name.
    #
    # @param name [String, Symbol] The name of the feature.
    # @return [Feature]
    def feature(name)
      if !name.is_a?(String) && !name.is_a?(Symbol)
        raise ArgumentError, "#{name} must be a String or Symbol"
      end

      @memoized_features[name.to_sym] ||= Feature.new(name, @adapter, instrumenter: instrumenter)
    end

    # Preload the features with the given names.
    #
    # @param names [Array<String,Symbol>] the names of the features
    # @return [Array<Feature>]
    def preload(names)
      features = names.map { |name| feature(name) }
      @adapter.get_multi(features)
      features
    end

    # Preload all the adapters features.
    #
    # @return [Array<Feature>]
    def preload_all
      keys = @adapter.get_all.keys
      keys.map { |key| feature(key) }
    end

    # Shortcut access to a feature instance by name.
    #
    # @param name [String, Symbol] The name of the feature.
    # @eturn [Feature].
    alias_method :[], :feature

    # Access a flipper group by name.
    #
    # @param name [String, Symbol] The name of the feature.
    # @return [Group]
    def group(name)
      Flipper.group(name)
    end

    # Returns a Set of the known features for this adapter.
    #
    # @return [Set<Feature>]
    def features
      adapter.features.map { |name| feature(name) }.to_set
    end

    # Cloud DSL method that does nothing for open source version.
    # @internal
    def sync
    end

    # Cloud DSL method that does nothing for open source version.
    # @internal
    def sync_secret
    end
  end
end
