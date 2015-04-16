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

      def description(value)
        if enabled?(value)
          groups = value.to_a.sort.map do |name|
            group_name, block_param = Types::Group.hydrate(name)
            [group_name.to_sym.inspect, block_param && block_param.inspect].compact.join(" ")
          end
          "groups (#{groups.join(', ')})"
        else
          'disabled'
        end
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
              group_name, block_param = Types::Group.hydrate(name)
              group = Flipper.group(group_name)
              group.match?(thing, block_param)
            rescue GroupNotRegistered
              false
            end
          }
        end
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end
    end
  end
end
