require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Features < Api::Action
          route %r{\A/features/?\Z}

          def get
            names = requested_feature_names
            exclude_gates = query_string_param('exclude_gates')&.downcase == "true"
            exclude_gate_names = query_string_param('exclude_gate_names')&.downcase == "true"

            features = if names
              if names.empty?
                []
              else
                existing_feature_names = names.keep_if do |feature_name|
                  feature_exists?(feature_name)
                end

                flipper.preload(existing_feature_names)
              end
            else
              flipper.features
            end

            decorated_features = features.map do |feature|
              Decorators::Feature.new(feature).as_json(
                exclude_gates: exclude_gates,
                exclude_gate_names: exclude_gate_names
              )
            end

            json_response(features: decorated_features)
          end

          def post
            feature_name = Typecast.to_feature_name(
              params.fetch('name') { json_error_response(:name_invalid) }
            )
            json_error_response(:name_invalid) if feature_name.empty?
            feature = flipper[feature_name]
            feature.add
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def requested_feature_names
            request_params = safe_params
            return nil unless request_params.key?('keys')

            keys = request_params['keys']
            return [] if keys.nil?
            return nil unless valid_feature_keys?(keys)
            return keys.map { |key| key || '' } if keys.is_a?(Array)

            raw_keys = raw_query_values("keys")
            return nil unless raw_keys
            return decoded_feature_names if raw_keys.empty?

            raw_keys.flat_map do |keys|
              if keys.include?(',')
                keys.split(',').map { |key| Rack::Utils.unescape(key) }
              else
                decoded_keys = Rack::Utils.unescape(keys)
                feature_exists?(decoded_keys) ? decoded_keys : decoded_keys.split(',')
              end
            end
          end

          def decoded_feature_names
            safe_params['keys'].split(',')
          end

          def raw_query_values(name)
            values = []
            request.query_string.to_s.split(/[&;]/).each do |part|
              next if part.empty?

              key, value = part.split('=', 2)
              decoded_key = decoded_query_component(key)
              return nil unless decoded_key
              next unless decoded_key == name
              return nil unless decoded_query_component(value.to_s)

              values << value.to_s
            end
            values
          end

          def query_string_param(name)
            value = string_param(name)
            return value if value || safe_params.key?(name)
            return nil if params_parse_failed?

            raw_values = raw_query_values(name)
            Rack::Utils.unescape(raw_values.last) if raw_values && !raw_values.empty?
          end

          def valid_feature_keys?(keys)
            return valid_param_string?(keys) unless keys.is_a?(Array)

            keys.all? { |key| key.nil? || valid_param_string?(key) }
          end

          def decoded_query_component(value)
            decoded = Rack::Utils.unescape(value)
            decoded if decoded.valid_encoding?
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end
