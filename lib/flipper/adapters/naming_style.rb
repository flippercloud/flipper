module Flipper
  module Adapters
    # An adapter that enforces a naming style for added features.
    #
    #   Flipper.configure do |config|
    #     config.use Flipper::Adapters::NamingStyle, :snake # or :camel, :kebab, :screaming_snake, or a Regexp
    #   end
    #
    class NamingStyle < Wrapper
      InvalidFormat = Class.new(Flipper::Error)

      PRESETS = {
        camel: /^([A-Z][a-z0-9]*)+$/, # CamelCase
        snake: /^[a-z0-9]+(_[a-z0-9]+)*$/, # snake_case
        kebab: /^[a-z0-9]+(-[a-z0-9]+)*$/, # kebab-case
        screaming_snake: /^[A-Z0-9]+(_[A-Z0-9]+)*$/, # SCREAMING_SNAKE_CASE
      }

      attr_reader :format

      def initialize(adapter, format = :snake)
        @format = format.is_a?(Regexp) ? format : PRESETS.fetch(format) {
          raise ArgumentError, "Unknown format: #{format.inspect}. Must be a Regexp or one of #{PRESETS.keys.join(', ')}"
        }

        super(adapter)
      end

      def add(feature)
        unless valid?(feature.key)
          raise InvalidFormat, "Feature key #{feature.key.inspect} does not match format #{format.inspect}"
        end

        super feature
      end

      def valid?(name)
        format.match?(name)
      end
    end
  end
end
