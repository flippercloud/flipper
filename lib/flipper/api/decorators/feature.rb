require 'json'

module Flipper
  module Api
    module Decorators
      class Feature < SimpleDelegator

        # Public: The feature being decorated
        alias_method :feature, :__getobj__

        # Serializes to JSON
        def to_json(options = {})
          json =  { 
            key: feature.key, 
            name: feature.name
          }
          JSON.generate(json)
        end
      end
    end
  end
end
