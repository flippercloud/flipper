module Flipper
  class DSL
    def initialize(adapter)
      @adapter = adapter
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
      features[name.to_sym] ||= Flipper::Feature.new(name, @adapter)
    end

    alias :[] :feature

    def group(name)
      Flipper.group(name)
    end

    def actor(actor_or_number)
      raise ArgumentError, "actor cannot be nil" if actor_or_number.nil?

      identifier = if actor_or_number.respond_to?(:identifier)
        actor_or_number.identifier
      elsif actor_or_number.respond_to?(:id)
        actor_or_number.id
      else
        actor_or_number
      end

      Flipper::Types::Actor.new(identifier)
    end

    def random(number)
      Flipper::Types::PercentageOfRandom.new(number)
    end

    def actors(number)
      Flipper::Types::PercentageOfActors.new(number)
    end

    private

    def features
      @features ||= {}
    end
  end
end
