require 'flipper'
require 'flipper/cli/command'
require 'flipper/cli/enable'
require 'flipper/cli/disable'
require 'flipper/cli/list'
require 'flipper/cli/show'
require 'flipper/cli/help'

module Flipper
  module CLI
    def self.run(argv = ARGV)
      Flipper::CLI::Base.new.run(argv)
    end

    class Base < Command
      def initialize(**args)
        # Program is always flipper, no matter how it's invoked
        super program_name: 'flipper', **args

        subcommand 'enable', Flipper::CLI::Enable
        subcommand 'disable', Flipper::CLI::Disable
        subcommand 'list', Flipper::CLI::List
        subcommand 'show', Flipper::CLI::Show
        subcommand 'help', Flipper::CLI::Help
      end
    end
  end
end
