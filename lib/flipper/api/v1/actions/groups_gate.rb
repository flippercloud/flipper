require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class GroupsGate < Api::Action
          route %r{features/[^/]*/groups/?\Z}

          def post
            ensure_valid_params
            feature = flipper[feature_name]
            feature.enable_group(group_name)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            ensure_valid_params
            feature = flipper[feature_name]
            feature.disable_group(group_name)
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def ensure_valid_params
            json_error_response(:feature_not_found) unless feature_names.include?(feature_name)
            json_error_response(:group_not_registered) unless Flipper.group_exists?(group_name)
          end

          def feature_name
            @feature_name ||= Rack::Utils.unescape(path_parts[-2])
          end

          def group_name
            @group_name ||= params['name']
          end

          def feature_names
            @feature_names ||= flipper.adapter.features
          end
        end
      end
    end
  end
end
