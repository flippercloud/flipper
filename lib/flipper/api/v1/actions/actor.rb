require 'flipper/api/action'
require 'flipper/api/v1/decorators/actor'

module Flipper
  module Api
    module V1
      module Actions
        class Actor < Api::Action
          include FeatureNameFromRoute

          route %r{\A/feature/(?<feature_name>.*)/actor/?\Z}

          def get
            return json_error_response(:flipper_id_invalid) if flipper_id.nil?
            return json_error_response(:feature_not_found) unless feature_exists?(feature_name)
            actor = Decorators::Actor.new(Flipper::Actor.new(flipper_id), flipper[feature_name])
            json_response(actor.as_json)
          end

          private

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end

          def flipper_id
            @flipper_id ||= params['flipper_id']
          end
        end
      end
    end
  end
end
