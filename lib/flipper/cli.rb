require 'optparse'

module Flipper
  class CLI < OptionParser
    def self.run(argv = ARGV)
      new.run(argv)
    end

    # Path to the local Rails application's environment configuration.
    DEFAULT_REQUIRE = "./config/environment"

    def initialize
      super

      # Program is always flipper, no matter how it's invoked
      @program_name = 'flipper'
      @require = ENV.fetch("FLIPPER_REQUIRE", DEFAULT_REQUIRE)
      @commands = {}

      %w[enable disable].each do |action|
        command action do |c|
          c.banner = "Usage: #{c.program_name} [options] <feature>"
          c.description = "#{action.to_s.capitalize} a feature"

          values = []

          c.on('-a id', '--actor=id', "#{action} for an actor") do |id|
            values << Actor.new(id)
          end
          c.on('-g name', '--group=name', "#{action} for a group") do |name|
            values << Types::Group.new(name)
          end
          c.on('-p NUM', '--percentage-of-actors=NUM', Numeric, "#{action} for a percentage of actors") do |num|
            values << Types::PercentageOfActors.new(num)
          end
          c.on('-t NUM', '--percentage-of-time=NUM', Numeric, "#{action} for a percentage of time") do |num|
            values << Types::PercentageOfTime.new(num)
          end

          c.action do |feature|
            load_environment!

            f = Flipper.feature(feature)

            if values.empty?
              f.send(action)
            else
              values.each { |value| f.send(action, value) }
            end

            puts feature_summary(f)
          end
        end
      end

      command 'list' do |c|
        c.description = "List defined features"
        c.action do
          load_environment!

          Flipper.features.each do |feature|
            puts feature_summary(feature)
          end
        end
      end

      command 'show' do |c|
        c.description = "Show a defined feature"
        c.action do |feature|
          load_environment!
          puts feature_summary(Flipper.feature(feature))
        end
      end

      command 'help' do |c|
        c.action do |command = nil|
          puts command ? @commands[command].help : help
        end
      end

      on_tail('-r path', "The path to load your application. Default: #{@require}") do |path|
        @require = path
      end

      # Options available on all commands
      on_tail('-h', '--help', 'Print help message') do
        puts help
        exit
      end

      # Set help documentation
      self.banner = "Usage: #{program_name} [options] <command>"
      separator ""
      separator "Commands:"

      pad = @commands.keys.map(&:length).max + 2
      @commands.each do |name, command|
        separator "  #{name.to_s.ljust(pad, " ")} #{command.description}" if command.description
      end

      separator ""
      separator "Options:"
    end

    def run(argv)
      command, *args = order(argv)

      if @commands[command]
        @commands[command].run(args)
      else
        puts help

        if command
          warn "Unknown command: #{command}"
          exit 1
        end
      end
    end

    # Helper method to define a new command
    def command(name, &block)
      @commands[name] = Command.new(program_name: "#{program_name} #{name}")
      block.call(@commands[name])
    end

    def load_environment!
      require File.expand_path(@require)
      # Ensure all of flipper gets loaded if it hasn't already.
      require 'flipper'
    rescue LoadError => e
      warn e.message
      exit 1
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
            "#{feature.percentage_of_time_value}% of time"
          end
        end.join(', ')
      end

      "#{feature.name.to_s.inspect} is #{summary}"
    end

    def pluralize(count, singular, plural)
      "#{count} #{count == 1 ? singular : plural}"
    end

    class Command < OptionParser
      attr_accessor :description

      def initialize(program_name: nil)
        super()
        @program_name = program_name
        @action = lambda { }
      end

      def run(argv)
        # Parse argv and call action with arguments
        @action.call(*permute(argv))
      end

      def action(&block)
        @action = block
      end
    end
  end
end
