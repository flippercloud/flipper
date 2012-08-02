module Flipper
  module Gates
    class Group < Gate
      Key = :groups

      def type_key
        Key
      end

      def toggle_class
        Toggles::Set
      end

      def open?(actor)
        return if actor.nil?
        groups.any? { |group| group.match?(actor) }
      end

      def group_names
        toggle.value
      end

      def groups
        group_names.map { |name| Flipper.groups.get(name) }.compact
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end
    end
  end
end
