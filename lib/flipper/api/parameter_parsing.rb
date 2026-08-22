require 'rack/utils'
require 'rack/multipart'
require 'json'

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
      JSON_WHITESPACE_BYTES = [9, 10, 13, 32].freeze
      PERCENTAGE_STRING = /\A[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/
      private_constant :JSON_WHITESPACE_BYTES
      private_constant :PERCENTAGE_STRING

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

      def self.valid_json?(object)
        pending = [object]
        until pending.empty?
          value = pending.pop
          case value
          when String
            return false unless value.valid_encoding?
          when Float
            return false unless value.finite?
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

      def self.read_bounded(input, limit)
        body = ''.b
        while body.bytesize < limit
          chunk = input.read(limit - body.bytesize)
          break if chunk.nil? || chunk.empty?

          body << chunk
        end
        body
      end

      def self.valid_percentage_string?(value)
        value.is_a?(String) && PERCENTAGE_STRING.match?(value)
      end

      def self.normalize_percentage(value)
        if value.is_a?(String) && value.match?(/[eE]/)
          Float(value)
        else
          value
        end
      end

      def self.parse_json(data)
        parsed = JSON.parse(data, allow_duplicate_key: true)
        scan_json_value(data, skip_json_whitespace(data, 0))
        parsed
      end

      def self.scan_json_value(data, index)
        index = skip_json_whitespace(data, index)
        case data.getbyte(index)
        when 123
          scan_json_object(data, index + 1)
        when 91
          scan_json_array(data, index + 1)
        when 34
          scan_json_string(data, index)
        else
          index += 1 while index < data.bytesize && !JSON_WHITESPACE_BYTES.include?(data.getbyte(index)) &&
            ![44, 93, 125].include?(data.getbyte(index))
          index
        end
      end
      private_class_method :scan_json_value

      def self.scan_json_object(data, index)
        keys = {}
        index = skip_json_whitespace(data, index)
        return index + 1 if data.getbyte(index) == 125

        loop do
          key_start = index
          index = scan_json_string(data, index)
          key = JSON.parse(data.byteslice(key_start, index - key_start))
          raise JSON::ParserError, "duplicate key #{key.inspect}" if keys.key?(key)

          keys[key] = true
          index = skip_json_whitespace(data, index) + 1
          index = scan_json_value(data, index)
          index = skip_json_whitespace(data, index)
          return index + 1 if data.getbyte(index) == 125

          index = skip_json_whitespace(data, index + 1)
        end
      end
      private_class_method :scan_json_object

      def self.scan_json_array(data, index)
        index = skip_json_whitespace(data, index)
        return index + 1 if data.getbyte(index) == 93

        loop do
          index = scan_json_value(data, index)
          index = skip_json_whitespace(data, index)
          return index + 1 if data.getbyte(index) == 93

          index = skip_json_whitespace(data, index + 1)
        end
      end
      private_class_method :scan_json_array

      def self.scan_json_string(data, index)
        index += 1
        while index < data.bytesize
          case data.getbyte(index)
          when 34
            return index + 1
          when 92
            index += 2
          else
            index += 1
          end
        end
        index
      end
      private_class_method :scan_json_string

      def self.skip_json_whitespace(data, index)
        index += 1 while JSON_WHITESPACE_BYTES.include?(data.getbyte(index))
        index
      end
      private_class_method :skip_json_whitespace

      # Rack raises for scalar/container conflicts in one order but silently
      # accepts the reverse order. Parse both orderings so the result does not
      # depend on which client-controlled shape appeared last.
      def self.parse_nested_query(data, separator = nil)
        parsed = if separator
          Rack::Utils.parse_nested_query(data, separator)
        else
          Rack::Utils.parse_nested_query(data)
        end
        parts = data.split(separator || Rack::Utils::DEFAULT_SEP, -1)
        if parts.length > 1
          reversed = parts.reverse.join('&')
          if separator
            Rack::Utils.parse_nested_query(reversed, separator)
          else
            Rack::Utils.parse_nested_query(reversed)
          end
        end
        parsed
      end
    end
  end
end
