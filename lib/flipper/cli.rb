require 'flipper'
require 'flipper/cli/command'
require 'flipper/cli/enable'
require 'flipper/cli/disable'
require 'flipper/cli/help'

module Flipper
  module CLI
    def self.run(argv = ARGV)
      Flipper::CLI::Base.new.run(argv)
    end

    class Base < Command
      # Path to the local Rails application's environment configuration.
      # Requiring this loads the application's configuration and classes.
      RAILS_ENVIRONMENT_RB = File.expand_path("config/environment")

      def initialize(**args)
        # Program is always flipper, no matter how it's invoked
        super program_name: 'flipper', **args

        subcommand('enable', Flipper::CLI::Enable)
        subcommand('disable', Flipper::CLI::Disable)
        subcommand('help', Flipper::CLI::Help)
      end

      def spawn(subcommand)
        # Initialize flipper before calling any subcommands
        initialize_flipper!
        super
      end

      private

      def initialize_flipper!
        # require RAILS_ENVIRONMENT_RB
      end
    end
  end
end
