require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'
require 'flipper/ui/expression_param_parser'

module Flipper
  module UI
    module Actions
      class ExpressionGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/expression/?\Z}

        def post
          render_read_only if read_only?
          halt view_response(:expressions_disabled) unless Flipper::UI.configuration.expressions_enabled

          feature = flipper[feature_name]

          case params['operation']
          when 'enable'
            begin
              parsed_expression = Flipper::UI::ExpressionParamParser.new(params["expression"]).parse
            rescue Flipper::UI::ExpressionParamParser::InvalidJSONError
              error = 'Expression JSON is not valid.'
              redirect_to("/features/#{Flipper::UI::Util.escape feature.key}?error=#{Flipper::UI::Util.escape error}")
            end

            begin
              expression = Flipper::Expression.build(parsed_expression)
            rescue NameError, ArgumentError
              error = 'Expression is not valid.'
              redirect_to("/features/#{Flipper::UI::Util.escape feature.key}?error=#{Flipper::UI::Util.escape error}")
            end

            feature.enable_expression expression
          when 'disable'
            feature.disable_expression
          end

          redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
        end
      end
    end
  end
end
