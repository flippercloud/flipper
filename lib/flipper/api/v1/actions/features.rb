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
            exclude_gates = params['exclude_gates']&.downcase == "true"
            exclude_gate_names = params['exclude_gate_names']&.downcase == "true"

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
            feature_name = params.fetch('name') { json_error_response(:name_invalid) }
            feature = flipper[feature_name]
            feature.add
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def requested_feature_names
            keys = params['keys']
            return keys.map(&:to_s) if keys.is_a?(Array)

            raw_keys = raw_query_values("keys")
            return decoded_feature_names if raw_keys.empty? || raw_keys.none? { |key| key.include?(',') }

            raw_keys.flat_map do |keys|
              keys.split(',').map { |key| Rack::Utils.unescape(key) }
            end
          end

          def decoded_feature_names
            keys = params['keys']
            return nil unless keys

            Array(keys).flat_map { |key| key.to_s.split(',') }
          end

          def raw_query_values(name)
            request.query_string.to_s.split(/[&;]/).each_with_object([]) do |part, values|
              key, value = part.split('=', 2)
              values << value.to_s if Rack::Utils.unescape(key) == name
            end
          end

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end
        end
      end
    end
  end
end
