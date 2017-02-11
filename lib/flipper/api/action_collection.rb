module Flipper
  module Api
    class ActionCollection
      def initialize
        @action_classes = []
      end

      def add(action_class)
        @action_classes << action_class
      end

      def action_for_request(request)
        @action_classes.detect do |action_class|
          request.path_info =~ action_class.regex
        end
      end
    end
  end
end
