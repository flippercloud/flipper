module Flipper
  module CLI
    class Show < Command
      def initialize(**args)
        super
        self.description = "Show a defined feature"
      end

      def call(feature)
        load_environment!
        puts feature_summary(Flipper.feature(feature))
      end
    end
  end
end
