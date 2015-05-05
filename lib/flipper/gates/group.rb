module Flipper
  module Gates
    class Group < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :group
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :groups
      end

      def data_type
        :set
      end

      def enabled?(value)
        !Typecast.to_set(value).empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value, options = {})
        if thing.nil?
          false
        else
          value.any? { |name|
            begin
              group = Flipper.group(name)
              group.match?(thing)
            rescue GroupNotRegistered
              false
            end
          }
        end
      end

      def wrap(thing)
        Types::Group.wrap(thing)
      end

      def protects?(thing)
        thing.is_a?(Types::Group)
      end
    end
  end
end
