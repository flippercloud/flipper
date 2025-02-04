require 'delegate'

module Flipper
  module Api
    module V1
      module Decorators
        class Actor < SimpleDelegator
          # Public: the actor and features.
          attr_reader :actor, :features

          def initialize(actor, features)
            @actor = actor
            @features = features
          end

          def as_json
            {
              'flipper_id' => actor.flipper_id,
              'features' => features_data,
            }
          end

          private

          def features_data
            features.each_with_object({}) do |feature, features_hash|
              features_hash[feature.name] = {
                'enabled' => feature.enabled?(actor),
              }
              features_hash
            end
          end
        end
      end
    end
  end
end
