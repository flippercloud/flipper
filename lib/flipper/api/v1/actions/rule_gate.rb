require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class RuleGate < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/rule/?\Z}

          def post
            ensure_valid_params
            feature = flipper[feature_name]
            feature.enable_rule Flipper::Expression.build(rule_hash)

            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          def delete
            feature = flipper[feature_name]
            feature.disable_rule

            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def ensure_valid_params
            json_error_response(:rule_type_invalid) if rule_type.nil?
            json_error_response(:rule_value_invalid) if rule_value.nil?
          end

          def rule_hash
            @rule_hash ||= request.env["parsed_request_body".freeze] || {}.freeze
          end

          def rule_type
            @rule_type ||= rule_hash["type".freeze]
          end

          def rule_value
            @rule_value ||= rule_hash["value".freeze]
          end
        end
      end
    end
  end
end
