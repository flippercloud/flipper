module Flipper
  module Rules
    module Properties
      DEFAULT_PROPERTIES = {}.freeze

      def self.from_actor(actor)
        return DEFAULT_PROPERTIES if actor.nil?

        properties = {}

        if actor.respond_to?(:flipper_properties)
          properties.update(actor.flipper_properties)
        else
          warn "#{actor.inspect} does not respond to `flipper_properties` but should."
        end

        if actor.respond_to?(:flipper_id)
          properties["flipper_id".freeze] = actor.flipper_id
        end

        properties
      end
    end
  end
end
