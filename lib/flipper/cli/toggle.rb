module Flipper
  module CLI
    class Toggle < Command
      def initialize(**args)
        super

        self.banner = "Usage: #{program_name} [options] <feature>"

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

      def call(feature)
        load_environment!

        f = Flipper.feature(feature)

        if @values.empty?
          f.send(action)
        else
          @values.each { |value| f.send(action, value) }
        end

        puts feature_summary(f)
      end
    end
  end
end
