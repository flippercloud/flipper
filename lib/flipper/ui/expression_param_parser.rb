module Flipper
  module UI
    # Internal: Used to parse expressions from the UI into a format that can be
    # used by Flipper::Expression.build
    class ExpressionParamParser
      class InvalidJSONError < StandardError ;end

      def initialize(expression)
        @expression = expression
      end

      def parse
        return {} unless @expression

        begin
          return JSON.parse(@expression) if @expression.is_a?(String)
        rescue JSON::ParserError
          raise InvalidJSONError
        end

        convert(@expression)
      end

      private

      def convert(node)
        return node unless node.is_a?(Hash)
        return node unless node.key?('type') && node.key?('args')

        type = node['type']
        args = node['args']

        args_array = []
        args.keys.sort.each { |k| args_array << convert(args[k]) } if args.is_a?(Hash)

        { type => args_array }
      end
    end
  end
end
