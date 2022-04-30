module Flipper
  module CLI
    class Toggle < Command
      def initialize(**args)
        super

        @values = []

        on('-a id', '--actor=id', "#{action} for an actor") do |id|
          @values << Actor.new(id)
        end
        on('-g name', '--group=name', "#{action} for a group") do |name|
          @values << Types::Group.new(name)
        end
        on('-p NUM', '--percentage-of-actors=NUM', Numeric, "#{action} for a percentage of actors") do |num|
          @values << Types::PercentageOfActors.new(num)
        end
        on('-t NUM', '--percentage-of-time=NUM', Numeric, "#{action} for a percentage of time") do |num|
          @values << Types::PercentageOfTime.new(num)
        end
      end

      def action
        raise NotImplementedError
      end

      def call(feature_name)
        feature = Flipper.feature(feature_name)

        if @values.empty?
          feature.send(action)
        else
          @values.each { |value| feature.send(action, value) }
        end

        puts feature_summary(feature)
      end

      def feature_summary(feature)
        summary = case feature.state
        when :on
          "fully enabled"
        when :off
          "disabled"
        else
          "enabled for " + feature.enabled_gates.map do |gate|
            case gate.name
            when :actor
              pluralize feature.actors_value.size, 'actor', 'actors'
            when :group
              pluralize feature.groups_value.size, 'group', 'groups'
            when :percentage_of_actors
              "#{feature.percentage_of_actors_value}% of actors"
            when :percentage_of_time
              "#{feature.percentage_of_time_value}% of actors"
            end
          end.join(', ')
        end

        "#{feature.name.to_s.inspect} is #{summary}"
      end

      def pluralize(count, singular, plural)
        "#{count} #{count == 1 ? singular : plural}"
      end
    end
  end
end
