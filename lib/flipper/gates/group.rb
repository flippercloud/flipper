module Flipper
  module Gates
    class Group < Gate
      Key = :groups

      def key
        @key ||= "#{@feature.name}.#{Key}"
      end

      def toggle
        @toggle ||= Toggles::Set.new(@feature.adapter, key)
      end

      def match?(actor)
        return if actor.nil?
        groups.any? { |group| group.match?(actor) }
      end

      def group_names
        toggle.value
      end

      def groups
        group_names.map { |name| Flipper::Types::Group.get(name) }.compact
      end

      def protects?(thing)
        thing.is_a?(Flipper::Types::Group)
      end
    end
  end
end
