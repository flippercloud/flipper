module Flipper
  module Gates
    class Group < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :group
      end

      # Internal: The piece of the adapter key that is unique to the gate class.
      def key
        :groups
      end

      def enable(thing)
        adapter.set_add adapter_key, thing.value
        true
      end

      def disable(thing)
        adapter.set_delete adapter_key, thing.value
        true
      end

      def enabled?
        !value.empty?
      end

      def value
        adapter.set_members adapter_key
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value)
        instrument(:open?, thing) { |payload|
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
        }
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end

      def description
        if enabled?
          group_names = value.to_a.sort.map { |name| name.to_sym.inspect }
          "groups (#{group_names.join(', ')})"
        else
          'disabled'
        end
      end
    end
  end
end
