require 'optparse'

module Flipper
  class CLI < OptionParser
    def self.run(argv = ARGV)
      new.run(argv)
    end

    # Path to the local Rails application's environment configuration.
    DEFAULT_REQUIRE = "./config/environment"

    attr_accessor :shell

    def initialize(stdout: $stdout, stderr: $stderr, shell: Bundler::Thor::Base.shell.new)
      super

      # Program is always flipper, no matter how it's invoked
      @program_name = 'flipper'
      @require = ENV.fetch("FLIPPER_REQUIRE", DEFAULT_REQUIRE)
      @commands = {}

      # Extend whatever shell to support output redirection
      @shell = shell.extend(ShellOutput)
      shell.redirect(stdout: stdout, stderr: stderr)

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
          c.on('-x expressions', '--expression=NUM', "#{action} for the given expression") do |expression|
            begin
              values << Flipper::Expression.build(JSON.parse(expression))
            rescue JSON::ParserError => e
              ui.error "JSON parse error #{e.message}"
              ui.trace(e)
              exit 1
            rescue ArgumentError => e
              ui.error "Invalid expression: #{e.message}"
              ui.trace(e)
              exit 1
            end
          end

          c.action do |feature|
            f = Flipper.feature(feature)

            if values.empty?
              f.send(action)
            else
              values.each { |value| f.send(action, value) }
            end

            ui.info feature_details(f)
          end
        end
      end

      command 'list' do |c|
        c.description = "List defined features"
        c.action do
          ui.info feature_summary(Flipper.features)
        end
      end

      command 'show' do |c|
        c.description = "Show a defined feature"
        c.action do |feature|
          ui.info feature_details(Flipper.feature(feature))
        end
      end

      command 'help' do |c|
        c.load_environment = false
        c.action do |command = nil|
          ui.info command ? @commands[command].help : help
        end
      end

      on_tail('-r path', "The path to load your application. Default: #{@require}") do |path|
        @require = path
      end

      # Options available on all commands
      on_tail('-h', '--help', 'Print help message') do
        ui.info help
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
        load_environment! if @commands[command].load_environment
        @commands[command].run(args)
      else
        ui.info help

        if command
          ui.error "Unknown command: #{command}"
          exit 1
        end
      end
    rescue OptionParser::InvalidOption => e
      ui.error e.message
      exit 1
    end

    # Helper method to define a new command
    def command(name, &block)
      @commands[name] = Command.new(program_name: "#{program_name} #{name}")
      block.call(@commands[name])
    end

    def load_environment!
      ENV["FLIPPER_CLOUD_LOGGING_ENABLED"] ||= "false"
      require File.expand_path(@require)
      # Ensure all of flipper gets loaded if it hasn't already.
      require 'flipper'
    rescue LoadError => e
      ui.error e.message
      exit 1
    end

    def feature_summary(features)
      features = Array(features)
      padding = features.map { |f| f.key.to_s.length }.max

      features.map do |feature|
        summary = case feature.state
        when :on
          colorize("⏺ enabled", [:GREEN])
        when :off
          "⦸ disabled"
        else
            "#{colorize("◯ enabled", [:YELLOW])} for " + feature.enabled_gates.map do |gate|
            case gate.name
            when :actor
              pluralize feature.actors_value.size, 'actor', 'actors'
            when :group
              pluralize feature.groups_value.size, 'group', 'groups'
            when :percentage_of_actors
              "#{feature.percentage_of_actors_value}% of actors"
            when :percentage_of_time
              "#{feature.percentage_of_time_value}% of time"
            when :expression
              "an expression"
            end
          end.join(', ')
        end

        colorize("%-#{padding}s" % feature.key, [:BOLD, :WHITE]) + " is #{summary}"
      end.join("\n")
    end

    def feature_details(feature)
      summary = case feature.state
      when :on
        colorize("⏺ enabled", [:GREEN])
      when :off
        "⦸ disabled"
      else
        lines = feature.enabled_gates.map do |gate|
          case gate.name
          when :actor
            [ pluralize(feature.actors_value.size, 'actor', 'actors') ] +
            feature.actors_value.map { |actor| "- #{actor}" }
          when :group
            [ pluralize(feature.groups_value.size, 'group', 'groups') ] +
            feature.groups_value.map { |group| "  - #{group}" }
          when :percentage_of_actors
            "#{feature.percentage_of_actors_value}% of actors"
          when :percentage_of_time
            "#{feature.percentage_of_time_value}% of time"
          when :expression
            json = indent(JSON.pretty_generate(feature.expression_value), 2)
            "the expression: \n#{colorize(json, [:MAGENTA])}"
          end
        end

        "#{colorize("◯ conditionally enabled", [:YELLOW])} for:\n" +
        indent(lines.flatten.join("\n"), 2)
      end

      "#{colorize(feature.key, [:BOLD, :WHITE])} is #{summary}"
    end

    def pluralize(count, singular, plural)
      "#{count} #{count == 1 ? singular : plural}"
    end

    def colorize(text, colors)
      ui.add_color(text, *colors)
    end

    def ui
      @ui ||= Bundler::UI::Shell.new.tap do |ui|
        ui.shell = shell
      end
    end

    def indent(text, spaces)
      text.gsub(/^/, " " * spaces)
    end

    # Redirect the shell's output to the given stdout and stderr streams
    module ShellOutput
      attr_reader :stdout, :stderr

      def redirect(stdout: $stdout, stderr: $stderr)
        @stdout, @stderr = stdout, stderr
      end
    end

    class Command < OptionParser
      attr_accessor :description, :load_environment

      def initialize(program_name: nil)
        super()
        @program_name = program_name
        @load_environment = true
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
