require 'flipper/ui/configuration/option'

module Flipper
  module UI
    class Configuration
      attr_reader :actors,
                  :delete,
                  :groups,
                  :percentage_of_actors,
                  :percentage_of_time

      def initialize
        @actors = Option.new("Actors", "Enable actors using the form above.")
        @groups = Option.new("Groups", "Enable groups using the form above.")
        @percentage_of_actors = Option.new("Percentage of Actors", "Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.") # rubocop:disable Metrics/LineLength
        @percentage_of_time = Option.new("Percentage of Time", "Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.") # rubocop:disable Metrics/LineLength
        @delete = Option.new("Danger Zone", "Deleting a feature removes it from the list of features and disables it for everyone.") # rubocop:disable Metrics/LineLength
      end
    end
  end
end
