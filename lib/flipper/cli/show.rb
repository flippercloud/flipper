module Flipper
  module CLI
    class Show < Command
      def call(feature)
        load_environment!
        puts feature_summary(Flipper.feature(feature))
      end
    end
  end
end
