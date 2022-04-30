require_relative './toggle'

module Flipper
  module CLI
    class Disable < Toggle
      def action
        :disable
      end
    end
  end
end
