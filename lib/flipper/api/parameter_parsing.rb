require 'rack/utils'
require 'rack/multipart'

module Flipper
  module Api
    module ParameterParsing
      ERROR_NAMES = [
        :InvalidParameterError,
        :ParameterTypeError,
        :ParamsTooDeepError,
        :QueryLimitError,
      ].freeze
      MULTIPART_ERROR_NAMES = [
        :BoundaryTooLongError,
        :EmptyContentError,
        :Error,
        :MissingInputError,
        :MultipartPartLimitError,
        :MultipartTotalPartLimitError,
      ].freeze

      def self.errors
        parsers = [Rack::Utils]
        parsers << Rack.const_get(:QueryParser, false) if Rack.const_defined?(:QueryParser, false)

        errors = parsers.each_with_object([]) do |parser, result|
          ERROR_NAMES.each do |name|
            result << parser.const_get(name, false) if parser.const_defined?(name, false)
          end
        end

        MULTIPART_ERROR_NAMES.each do |name|
          if Rack::Multipart.const_defined?(name, false)
            errors << Rack::Multipart.const_get(name, false)
          end
        end

        has_named_depth_error = parsers.any? do |parser|
          parser.const_defined?(:ParamsTooDeepError, false)
        end
        # Rack 2.0 reports nesting and key-space limits as plain RangeError.
        errors << RangeError unless has_named_depth_error
        errors.uniq
      end

      def self.valid_encoding?(object)
        pending = [object]
        until pending.empty?
          value = pending.pop
          case value
          when String
            return false unless value.valid_encoding?
          when Array
            pending.concat(value)
          when Hash
            value.each do |key, nested_value|
              pending << key
              pending << nested_value
            end
          end
        end
        true
      end

      # Rack raises for scalar/container conflicts in one order but silently
      # accepts the reverse order. Parse both orderings so the result does not
      # depend on which client-controlled shape appeared last.
      def self.parse_nested_query(data)
        parsed = Rack::Utils.parse_nested_query(data)
        parts = data.split(Rack::Utils::DEFAULT_SEP, -1)
        Rack::Utils.parse_nested_query(parts.reverse.join('&')) if parts.length > 1
        parsed
      end
    end
  end
end
