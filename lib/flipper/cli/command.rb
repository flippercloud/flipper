require 'optparse'

module Flipper
  module CLI
    class Command < OptionParser
      attr_reader :options, :subcommands, :parent

      def initialize(parent: nil, options: parent&.options || {}, program_name: nil)
        super()
        @subcommands = {}
        @options = options
        @program_name = program_name
        @parent = parent

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

      private

      # Internal: Initialize a subcommand with state from the current command
      def spawn(subcommand)
        subcommands.fetch(subcommand).new(
          parent: self,
          program_name: "#{program_name} #{subcommand}"
        )
      end
    end
  end
end
