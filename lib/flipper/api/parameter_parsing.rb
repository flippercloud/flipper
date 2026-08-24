require 'rack/utils'
require 'rack/multipart'

module Flipper
  module Api
    module ParameterParsing
      InvalidParameterShape = Class.new(StandardError)

      class RecordingQueryParser
        attr_reader :fields

        def initialize(parser)
          @parser = parser
          @fields = []
        end

        def make_params
          @parser.make_params
        end

        def param_depth_limit
          @parser.param_depth_limit
        end

        def normalize_params(params, name, value, *rest)
          @fields << [name, rest]
          @parser.normalize_params(params, name, value, *rest)
        rescue *ParameterParsing.errors => error
          raise InvalidParameterShape, error.message
        end
      end
      private_constant :RecordingQueryParser

      class DiscardIO
        def <<(_content)
          self
        end

        def binmode
          self
        end

        def close
        end

        def rewind
          self
        end
      end
      private_constant :DiscardIO

      ERROR_NAMES = [
        :InvalidParameterError,
        :ParameterTypeError,
        :ParamsTooDeepError,
        :QueryLimitError,
      ].freeze
      def self.errors
        parsers = [Rack::Utils]
        parsers << Rack.const_get(:QueryParser, false) if Rack.const_defined?(:QueryParser, false)

        errors = parsers.each_with_object([]) do |parser, result|
          ERROR_NAMES.each do |name|
            result << parser.const_get(name, false) if parser.const_defined?(name, false)
          end
        end

        has_named_depth_error = parsers.any? do |parser|
          parser.const_defined?(:ParamsTooDeepError, false)
        end
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

      def self.read_bounded(input, limit)
        body = ''.b
        while body.bytesize < limit
          chunk = input.read(limit - body.bytesize)
          break if chunk.nil? || chunk.empty?

          body << chunk
        end
        body
      end

      # Rack raises for scalar/container conflicts in one order but accepts the
      # reverse order. Parse both orderings so client-controlled ordering cannot
      # decide whether a mutation is accepted.
      def self.parse_nested_query(data)
        parsed = Rack::Utils.parse_nested_query(data)
        parts = data.split(Rack::Utils::DEFAULT_SEP, -1)
        if parts.length > 1
          Rack::Utils.parse_nested_query(parts.reverse.join('&'))
        end
        parsed
      end

      # Rack's multipart parser accepts scalar/container conflicts in one field
      # order. Record the fields during an otherwise normal parse, then replay
      # them in reverse through Rack's own query parser. Uploaded bytes are
      # discarded because only field names matter to this validation pass.
      def self.validate_multipart_shapes(env)
        input = env['rack.input'.freeze]
        parser = RecordingQueryParser.new(Rack::Utils.default_query_parser)
        validation_env = env.dup
        validation_env.delete_if { |key, _| key.start_with?('rack.request.') }
        validation_env['rack.multipart.tempfile_factory'.freeze] = lambda do |*|
          DiscardIO.new
        end

        input.rewind
        Rack::Multipart.parse_multipart(validation_env, parser)
        replay_parser = Rack::Utils.default_query_parser
        replay_params = replay_parser.make_params
        parser.fields.reverse_each do |name, rest|
          begin
            replay_parser.normalize_params(replay_params, name, ''.freeze, *rest)
          rescue *errors => error
            raise InvalidParameterShape, error.message
          end
        end
      ensure
        input.rewind if input && input.respond_to?(:rewind)
      end
    end
  end
end
