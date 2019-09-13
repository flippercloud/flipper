# frozen_string_literal: true

require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class ClearFeature < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/clear/?\Z}

          def delete
            feature = flipper[feature_name]
            feature.clear
            json_response({}, 204)
          end
        end
      end
    end
  end
end
