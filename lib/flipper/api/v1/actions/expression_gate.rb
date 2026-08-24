require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class ExpressionGate < Api::Action
          include FeatureNameFromRoute

          route %r{\A/features/(?<feature_name>.*)/expression/?\Z}

          def post
            feature = flipper[feature_name]

            begin
              expression = Flipper::Expression.build(expression_hash)
              feature.enable_expression expression
              decorated_feature = Decorators::Feature.new(feature)
              json_response(decorated_feature.as_json, 200)
            rescue NameError, ArgumentError
              json_error_response(:expression_invalid)
            end
          end

          def delete
            feature = flipper[feature_name]
            feature.disable_expression

            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def expression_hash
            @expression_hash ||= request.env["parsed_request_body".freeze] || {}.freeze
          end
        end
      end
    end
  end
end
