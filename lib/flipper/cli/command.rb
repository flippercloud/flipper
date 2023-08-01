require 'optparse'

module Flipper
  module CLI
    class Command < OptionParser
      # Path to the local Rails application's environment configuration.
      DEFAULT_REQUIRE = "./config/environment"

      attr_reader :options, :subcommands, :parent

      def initialize(parent: nil, options: parent&.options || {}, program_name: nil)
        super()
        @subcommands = {}
        @options = options
        @program_name = program_name
        @parent = parent

        options[:require] ||= ENV.fetch("FLIPPER_REQUIRE", DEFAULT_REQUIRE)

        on_tail('-r path', "The path to load your application. Default: #{options[:require]}") do |path|
          options[:require] = path
        end

        # Options available on all commands
        on_tail('-h', '--help', 'Print help message') do
          puts help
          exit
        end
      end

      def run(argv)
        # Parse argv and call command with arguments
        call *order(argv)
      end

      # Default command implementation will delegate to any subcommands, if they exist
      def call(subcommand = nil, *args)
        if subcommands[subcommand]
          spawn(subcommand).run(args)
        else
          puts help

          if subcommand
            warn "Unknown command: #{subcommand}"
            exit 1
          end
        end
      end

      # Helper method to define a new subcommand
      def subcommand(name, command)
        @subcommands[name] = command
      end

      def load_environment!
        require File.expand_path(options[:require])
      rescue LoadError => e
        warn e.message
        exit 1
      end

      # Internal: Initialize a subcommand with state from the current command
      def spawn(subcommand)
        subcommands.fetch(subcommand).new(
          parent: self,
          program_name: "#{program_name} #{subcommand}"
        )
      end

      private

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
