require 'flipper/exporters/json/export'
require 'flipper/api/action'
require 'flipper/api/expression_validation'
require 'flipper/api/v1/decorators/feature'
require 'flipper/expression'
require 'flipper/types/percentage_of_actors'
require 'flipper/types/percentage_of_time'

module Flipper
  module Api
    module V1
      module Actions
        class Import < Api::Action
          route %r{\A/import/?\Z}

          GATE_NAMES = %w[
            actors
            boolean
            expression
            groups
            percentage_of_actors
            percentage_of_time
          ].freeze
          def post
            body = read_import_body
            export = build_import_export(body)
            flipper.import(export)
            json_response({}, 204)
          end

          private

          def read_import_body
            request.body.rewind if request.body.respond_to?(:rewind)
            max = Flipper::Exporters::Json::Export::MAX_BYTES
            # Read at most one byte past the limit so an oversized body is caught
            # without buffering the whole thing into memory.
            body = ParameterParsing.read_bounded(request.body, max + 1)
            request.body.rewind if request.body.respond_to?(:rewind)
            json_error_response(:import_invalid) if body.bytesize > max
            body
          end

          def build_import_export(body)
            payload = ParameterParsing.parse_json(body)
            validate_import_payload!(payload)
            Flipper::Exporters::Json::Export.new(contents: Typecast.to_json(payload))
          rescue JSON::ParserError, Flipper::Exporters::Json::InvalidError
            json_error_response(:import_invalid)
          end

          def validate_import_payload!(payload)
            invalid_import! unless payload.is_a?(Hash)
            invalid_import! unless ParameterParsing.valid_json?(payload)

            features = payload['features']
            invalid_import! unless features.is_a?(Hash)
            features.each do |feature_name, gates|
              invalid_import! unless feature_name.is_a?(String)
              invalid_import! unless gates.is_a?(Hash)
              invalid_import! unless (gates.keys - GATE_NAMES).empty?
              validate_gate_values!(gates)
            end
          end

          def validate_gate_values!(gates)
            %w[actors groups].each do |gate|
              value = gates[gate] ||= []
              invalid_import! unless value.is_a?(Array)
              invalid_import! unless value.all? { |item| item.is_a?(String) }
            end

            boolean = gates['boolean']
            unless boolean.nil? || boolean.is_a?(String) || boolean.is_a?(Numeric) || boolean == true || boolean == false
              invalid_import!
            end

            validate_percentage!(gates['percentage_of_actors'], Flipper::Types::PercentageOfActors)
            validate_percentage!(gates['percentage_of_time'], Flipper::Types::PercentageOfTime)

            expression = gates['expression']
            return if expression.nil?
            invalid_import! unless expression.is_a?(Hash)
            ExpressionValidation.build(expression)
          rescue ArgumentError, NameError
            invalid_import!
          end

          def validate_percentage!(value, type)
            invalid_import! unless value.nil? || value.is_a?(String) || value.is_a?(Numeric)
            type.new(value || 0)
          end

          def invalid_import!
            raise Flipper::Exporters::Json::InvalidError
          end

          def parse_request_params?
            false
          end
        end
      end
    end
  end
end
