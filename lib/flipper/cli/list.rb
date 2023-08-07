module Flipper
  module CLI
    class List < Command
      def initialize(**args)
        super
        self.description = "List defined features"
      end

      def call
        load_environment!

        Flipper.features.each do |feature|
          puts feature_summary(feature)
        end
      end
    end
  end
end
