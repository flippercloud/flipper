require 'flipper/adapter'
require 'flipper/instrumenters/noop'

module Flipper
  class DSL
    # Private
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumenter

    # Public: Returns a new instance of the DSL.
    #
    # adapter - The adapter that this DSL instance should use.
    # options - The Hash of options.
    #           :instrumenter - What should be used to instrument all the things.
    def initialize(adapter, options = {})
      @instrumenter = options.fetch(:instrumenter, Flipper::Instrumenters::Noop)
      @adapter = Adapter.wrap(adapter, :instrumenter => @instrumenter)
      @memoized_features = {}
    end

    # Public: Check if a feature is enabled.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the enabled check.
    #
    # Returns true if feature is enabled, false if not.
    def enabled?(name, *args)
      feature(name).enabled?(*args)
    end

    # Public: Enable a feature.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the feature instance enable call.
    #
    # Returns the result of the feature instance enable call.
    def enable(name, *args)
      feature(name).enable(*args)
    end

    # Public: Disable a feature.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the feature instance enable call.
    #
    # Returns the result of the feature instance disable call.
    def disable(name, *args)
      feature(name).disable(*args)
    end

    # Public: Access a feature instance by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Feature.
    def feature(name)
      if !name.is_a?(String) && !name.is_a?(Symbol)
        raise ArgumentError, "#{name} must be a String or Symbol"
      end

      @memoized_features[name.to_sym] ||= Feature.new(name, @adapter, {
        :instrumenter => instrumenter,
      })
    end

    # Public: Shortcut access to a feature instance by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Feature.
    alias_method :[], :feature

    # Public: Shortcut for getting a boolean type instance.
    #
    # value - The true or false value for the boolean.
    #
    # Returns a Flipper::Types::Boolean instance.
    def boolean(value = true)
      Types::Boolean.new(value)
    end

    # Public: Event shorter shortcut for getting a boolean type instance.
    #
    # value - The true or false value for the boolean.
    #
    # Returns a Flipper::Types::Boolean instance.
    alias_method :bool, :boolean

    # Public: Access a flipper group by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Group.
    # Raises Flipper::GroupNotRegistered if group has not been registered.
    def group(name)
      Flipper.group(name)
    end

    # Public: Wraps an object as a flipper actor.
    #
    # thing - The object that you would like to wrap.
    #
    # Returns an instance of Flipper::Types::Actor.
    # Raises ArgumentError if thing not wrappable.
    def actor(thing)
      Types::Actor.new(thing)
    end

    # Public: Shortcut for getting a percentage of random instance.
    #
    # number - The percentage of random that should be enabled.
    #
    # Returns Flipper::Types::PercentageOfRandom.
    def random(number)
      Types::PercentageOfRandom.new(number)
    end
    alias_method :percentage_of_random, :random

    # Public: Shortcut for getting a percentage of actors instance.
    #
    # number - The percentage of actors that should be enabled.
    #
    # Returns Flipper::Types::PercentageOfActors.
    def actors(number)
      Types::PercentageOfActors.new(number)
    end
    alias_method :percentage_of_actors, :actors

    # Internal: Returns a Set of the known features for this adapter.
    #
    # Returns Set of Flipper::Feature instances.
    def features
      adapter.features.map { |name| feature(name) }.to_set
    end
  end
end
