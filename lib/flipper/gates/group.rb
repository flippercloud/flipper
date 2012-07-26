module Flipper
  module Gates
    class Group < Gate
      def key
        @key ||= "#{@feature.name}.groups"
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
        group_names.map { |name| Flipper::Group.get(name) }.compact
      end

      def protects?(thing)
        thing.is_a?(Flipper::Group)
      end
    end
  end
end
