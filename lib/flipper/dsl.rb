require 'flipper/adapter'

module Flipper
  class DSL
    attr_reader :adapter

    def initialize(adapter)
      @adapter = Adapter.wrap(adapter)
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
      memoized_features[name.to_sym] ||= Feature.new(name, @adapter)
    end

    alias :[] :feature

    def group(name)
      Flipper.group(name)
    end

    def actor(thing)
      Flipper::Types::Actor.new(thing)
    end

    def random(number)
      Flipper::Types::PercentageOfRandom.new(number)
    end

    def actors(number)
      Flipper::Types::PercentageOfActors.new(number)
    end

    def features
      adapter.set_members('features')
    end

    private

    def memoized_features
      @memoized_features ||= {}
    end
  end
end
