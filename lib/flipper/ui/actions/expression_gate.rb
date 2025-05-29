require 'flipper/ui/action'
require 'flipper/ui/decorators/feature'
require 'flipper/ui/util'

module Flipper
  module UI
    module Actions
      class ExpressionGate < UI::Action
        include FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)/expression/?\Z}

        # Map form operators to expression class names using dynamic lookup
        OPERATOR_MAPPING = {
          'eq' => 'Equal',
          'ne' => 'NotEqual',
          'gt' => 'GreaterThan',
          'gte' => 'GreaterThanOrEqualTo',
          'lt' => 'LessThan',
          'lte' => 'LessThanOrEqualTo'
        }.freeze

        def post
          render_read_only if read_only?

          feature = flipper[feature_name]

          case params['operation']
          when 'enable'
            expression = Flipper::Expression.build(parse_expression_params)
            feature.enable_expression expression
          when 'disable'
            feature.disable_expression
          end

          redirect_to("/features/#{Flipper::UI::Util.escape feature.key}")
        end

        private

        def parse_expression_params
          # Check if this is a complex expression (any/all)
          if params['complex_expression_type']
            parse_complex_expression_params
          else
            parse_simple_expression_params
          end
        end

        def parse_simple_expression_params
          property = params['expression_property'].to_s.strip
          operator = params['expression_operator'].to_s.strip
          value = params['expression_value'].to_s.strip

          # Convert value to appropriate type and map operator
          parsed_value = convert_value_to_type(value, property)
          expression_type = OPERATOR_MAPPING[operator]

          # Build expression hash in the format: {"Equal": [{"Property": ["plan"]}, "basic"]}
          {
            expression_type => [
              { "Property" => [property] },
              parsed_value
            ]
          }
        end

        def parse_complex_expression_params
          complex_type = params['complex_expression_type'].to_s.strip
          complex_expressions = params['complex_expressions'] || {}

          # Build array of simple expressions
          expressions = []
          complex_expressions.each do |index, expression_data|
            property = expression_data['property'].to_s.strip
            operator = expression_data['operator'].to_s.strip
            value = expression_data['value'].to_s.strip

            next if property.empty? || operator.empty? || value.empty?

            # Convert value to appropriate type and map operator
            parsed_value = convert_value_to_type(value, property)
            expression_type = OPERATOR_MAPPING[operator]

            # Build individual expression
            expressions << {
              expression_type => [
                { "Property" => [property] },
                parsed_value
              ]
            }
          end

          # Build complex expression hash
          case complex_type
          when 'any'
            { "Any" => expressions }
          when 'all'
            { "All" => expressions }
          else
            raise "Unknown complex expression type: #{complex_type}"
          end
        end

        def convert_value_to_type(value, property)
          property_type = property_type_for(property)

          case property_type.to_s
          when 'boolean'
            value == 'true'
          when 'number'
            value.include?('.') ? value.to_f : value.to_i
          else # string or unknown property
            value
          end
        end

        def property_type_for(property_name)
          properties = UI.configuration.expression_properties
          return nil unless properties

          # Try string key first, then symbol key
          definition = properties[property_name] || properties[property_name.to_sym]
          return nil unless definition

          definition[:type] || definition['type']
        end
      end
    end
  end
end
