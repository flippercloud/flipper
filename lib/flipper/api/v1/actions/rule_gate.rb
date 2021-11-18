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
            feature = flipper[feature_name]

            begin
              expression = Flipper::Expression.build(rule_hash)
              feature.enable_rule expression
              decorated_feature = Decorators::Feature.new(feature)
              json_response(decorated_feature.as_json, 200)
            rescue NameError => exception
              json_error_response(:expression_invalid)
            end
          end

          def delete
            feature = flipper[feature_name]
            feature.disable_rule

            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def rule_hash
            @rule_hash ||= request.env["parsed_request_body".freeze] || {}.freeze
          end
        end
      end
    end
  end
end
