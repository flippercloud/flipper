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
          group_names = value.to_a.sort.map { |name| name.to_sym.inspect }
          "groups (#{group_names.join(', ')})"
        else
          'disabled'
        end
      end

      def enabled?(value)
        !GateValues.to_set(value).empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(thing, value, options = {})
        instrument(:open?, thing) { |payload|
          payload[:feature_name] = options.fetch(:feature_name)

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
    end
  end
end
