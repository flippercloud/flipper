require 'flipper/ui/configuration/option'

module Flipper
  module UI
    class Configuration
      attr_reader :actors,
                  :boolean,
                  :delete,
                  :groups,
                  :percentage_of_actors,
                  :percentage_of_time

      def initialize
        @actors = Option.new("Enable actors using the form above.")
        @boolean = Option.new("Enable or disable this feature for <strong>everyone</strong> with one click.")
        @groups = Option.new("Enable groups using the form above.")
        @percentage_of_actors = Option.new("Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.")
        @percentage_of_time = Option.new("Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.")
        @delete = Option.new("Deleting a feature removes it from the list of features and disables it for everyone.")
      end
    end
  end
end
