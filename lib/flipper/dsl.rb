require 'flipper/adapter'
require 'flipper/noop_instrumentor'

module Flipper
  class DSL
    # Private
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumentor

    def initialize(adapter, options = {})
      @adapter = Adapter.wrap(adapter)
      @instrumentor = options.fetch(:instrumentor) { Flipper::NoopInstrumentor }
      @memoized_features = {}
    end

    def enabled?(name, *args)
      feature(name).enabled?(*args)
    end

    def disabled?(name, *args)
      !enabled?(name, *args)
    end

    def enable(name, *args)
      feature(name).enable(*args)
    end

    def disable(name, *args)
      feature(name).disable(*args)
    end

    def feature(name)
      @memoized_features[name.to_sym] ||= Feature.new(name, @adapter, {
        :instrumentor => instrumentor,
      })
    end

    alias_method :[], :feature

    def group(name)
      Flipper.group(name)
    end

    def actor(thing)
      Types::Actor.new(thing)
    end

    def random(number)
      Types::PercentageOfRandom.new(number)
    end
    alias :percentage_of_random :random

    def actors(number)
      Types::PercentageOfActors.new(number)
    end
    alias :percentage_of_actors :actors

    def features
      adapter.features.map { |name| feature(name) }.to_set
    end
  end
end
