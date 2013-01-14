module Flipper
  module Gates
    class Group < Gate
      def name
        :group
      end

      def type_key
        :groups
      end

      def toggle_class
        Toggles::Set
      end

      def open?(thing)
        instrument(:open, thing) {
          if thing.nil?
            false
          else
            groups.any? { |group| group.match?(thing) }
          end
        }
      end

      def group_names
        toggle.value
      end

      def groups
        group_names.map { |name| Flipper.group(name) }.compact
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end
    end
  end
end
