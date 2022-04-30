require_relative './toggle'

module Flipper
  module CLI
    class Enable < Toggle
      def action
        :enable
      end
    end
  end
end
