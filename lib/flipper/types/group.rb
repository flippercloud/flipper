module Flipper
  module Types
    class Group < Type

      def self.wrap(group_or_name)
        return group_or_name if group_or_name.is_a?(self)
        new(group_or_name)
      end

      attr_reader :value

      def initialize(name, &block)
        name = name.to_sym

        # Make sure there's a registered group with this name.
        Flipper.group(name)

        @value = name
      end
    end
  end
end
