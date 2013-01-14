require 'flipper/adapter'
require 'flipper/instrumentors/noop'

module Flipper
  class DSL
    # Private
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumentor

    # Public: Returns a new instance of the DSL.
    #
    # adapter - The adapter that this DSL instance should use.
    # options - The Hash of options.
    #           :instrumentor - What should be used to instrument all the things.
    def initialize(adapter, options = {})
      @instrumentor = options.fetch(:instrumentor, Flipper::Instrumentors::Noop)
      @adapter = Adapter.wrap(adapter, :instrumentor => @instrumentor)
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

    # Public: Check if a feature is disabled.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the disabled check.
    #
    # Returns true if feature is disabled, false if not.
    def disabled?(name, *args)
      feature(name).disabled?(*args)
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
      @memoized_features[name.to_sym] ||= Feature.new(name, @adapter, {
        :instrumentor => instrumentor,
      })
    end

    # Public: Shortcut access to a feature instance by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Feature.
    alias_method :[], :feature

    # Public: Access a flipper group by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Group.
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
