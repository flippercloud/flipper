module Flipper
  module Api
    module V1
      module Decorators
        class Actor < SimpleDelegator
          # Public: the actor and feature.
          attr_reader :actor, :feature

          def initialize(actor, feature)
            @actor = actor
            @feature = feature
          end

          def as_json
            {
              'flipper_id' => actor.flipper_id,
              'feature' => feature,
              'enabled' => enabled?,
            }
          end

          private

          def enabled?
            feature.enabled?(actor)
          end
        end
      end
    end
  end
end
