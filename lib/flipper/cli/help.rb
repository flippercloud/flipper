module Flipper
  module CLI
    class Help < Command
      def call(subcommand = nil)
        puts subcommand ? parent.spawn(subcommand).help : parent.help
      end
    end
  end
end
