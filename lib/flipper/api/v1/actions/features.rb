require 'flipper/api/action'
require 'flipper/api/v1/decorators/feature'

module Flipper
  module Api
    module V1
      module Actions
        class Features < Api::Action
          route %r{\A/features/?\Z}

          # Eagerly initialized so multi-threaded boot can't race on lazy `||=`.
          @response_extensions = []

          # Public: Procs registered here are called per GET request. Each
          # receives the action instance and should return a Hash; the hashes
          # are merged into the response body in registration order. Built-in
          # keys (like :features) always win over extension keys to prevent
          # accidental clobbering. Use this to add fields like protocol
          # versions, server capabilities, or feature counts without
          # subclassing or monkey-patching.
          #
          # Example:
          #   Flipper::Api::V1::Actions::Features.response_extensions << ->(action) {
          #     { version: action.request.env["x-version"].to_i }
          #   }
          def self.response_extensions
            @response_extensions
          end

          def get
            keys = params['keys']
            exclude_gates = params['exclude_gates']&.downcase == "true"
            exclude_gate_names = params['exclude_gate_names']&.downcase == "true"

            features = if keys
              names = keys.split(',')
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

            extras = self.class.response_extensions.reduce({}) do |memo, ext|
              memo.merge(ext.call(self))
            end
            json_response(extras.merge(features: decorated_features))
          end

          def post
            feature_name = params.fetch('name') { json_error_response(:name_invalid) }
            feature = flipper[feature_name]
            feature.add
            decorated_feature = Decorators::Feature.new(feature)
            json_response(decorated_feature.as_json, 200)
          end

          private

          def feature_exists?(feature_name)
            flipper.features.map(&:key).include?(feature_name)
          end
        end
      end
    end
  end
end
