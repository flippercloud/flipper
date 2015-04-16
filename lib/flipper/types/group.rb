module Flipper
  module Types
    class Group < Type
      SEPARATOR = "\x1E".freeze

      def self.dehydrate(group_name, block_param)
        [group_name, block_param].compact.join(SEPARATOR)
      end

      def self.hydrate(dehydrated)
        dehydrated.to_s.split(SEPARATOR, 2)
      end

      def self.wrap(group_or_name, block_param = nil)
        if group_or_name.is_a?(self)
          unless block_param.nil?
            raise ArgumentError.new("Cannot pass a Flipper::Types::Group and a block parameter")
          end
          group_or_name
        else
          new(group_or_name, block_param)
        end
      end

      attr_reader :value

      def initialize(group_name, block_param = nil)
        group_name = group_name.to_sym

        # Make sure there's a registered group with this name.
        Flipper.group(group_name)

        if block_param && !block_param.respond_to?(:to_str)
          raise ArgumentError.new("#{block_param.inspect} must respond to to_str, but does not")
        end

        @value = self.class.dehydrate(group_name, block_param && block_param.to_str)
      end
    end
  end
end
