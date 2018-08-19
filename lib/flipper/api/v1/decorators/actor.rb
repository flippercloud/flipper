module Flipper
  module Api
    module V1
      module Decorators
        class Actor < SimpleDelegator
          # Public: the actor and feature.
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
            features.map do |feature|
              {
                'feature' => feature.name,
                'enabled' => feature.enabled?(actor),
              }
            end
          end
        end
      end
    end
  end
end
