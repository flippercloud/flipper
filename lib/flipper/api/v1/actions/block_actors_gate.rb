require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class BlockActorsGate < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/block_actors/?\Z}

          def post
            ensure_valid_params
            feature = flipper[feature_name]
            actor = Actor.new(flipper_id)
            feature.block_actor(actor)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            ensure_valid_params
            feature = flipper[feature_name]
            actor = Actor.new(flipper_id)
            feature.unblock_actor(actor)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def ensure_valid_params
            json_error_response(:flipper_id_invalid) if flipper_id.nil?
          end

          def flipper_id
            @flipper_id ||= params['flipper_id']
          end
        end
      end
    end
  end
end
