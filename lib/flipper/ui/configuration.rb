require 'flipper/ui/configuration/option'

module Flipper
  module UI
    class Configuration
      attr_reader :actors,
                  :delete,
                  :groups,
                  :percentage_of_actors,
                  :percentage_of_time

      attr_accessor :banner_text,
                    :banner_class

      # Public: If you set this, the UI will always have a first breadcrumb that
      # says "App" which points to this href. The href can be a path (ie: "/")
      # or full url ("https://app.example.com/").
      attr_accessor :application_breadcrumb_href

      # Public: Is feature creation allowed from the UI? Defaults to true. If
      # set to false, users of the UI cannot create features. All feature
      # creation will need to be done through the configured flipper instance.
      attr_accessor :feature_creation_enabled

      # Public: Is feature deletion allowed from the UI? Defaults to true. If
      # set to false, users won't be able to delete features from the UI.
      attr_accessor :feature_removal_enabled

      # Public: Are you feeling lucky? Defaults to true. If set to false, users
      # won't see a videoclip of Taylor Swift when there aren't any features
      attr_accessor :fun

      # Public: What should show up in the form to add actors. This can be
      # different per application since flipper_id's can be whatever an
      # application needs. Defaults to "a flipper id".
      attr_accessor :add_actor_placeholder

      # Public: If you set this, Flipper::UI will fetch descriptions
      # from your external source. Descriptions for `features` will be shown on `feature`
      # and `features` pages. Defaults to empty block.
      attr_accessor :descriptions_source

      VALID_BANNER_CLASS_VALUES = %w(
        danger
        dark
        info
        light
        primary
        secondary
        success
        warning
      ).freeze

      DEFAULT_DESCRIPTIONS_SOURCE = ->(_keys) { {} }

      def initialize
        @actors = Option.new("Actors", "Enable actors using the form above.")
        @groups = Option.new("Groups", "Enable groups using the form above.")
        @percentage_of_actors = Option.new("Percentage of Actors", "Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.")
        @percentage_of_time = Option.new("Percentage of Time", "Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.")
        @delete = Option.new("Danger Zone", "Deleting a feature removes it from the list of features and disables it for everyone.")
        @banner_text = nil
        @banner_class = 'danger'
        @feature_creation_enabled = true
        @feature_removal_enabled = true
        @fun = true
        @add_actor_placeholder = "a flipper id"
        @descriptions_source = DEFAULT_DESCRIPTIONS_SOURCE
      end

      def using_descriptions?
        @descriptions_source != DEFAULT_DESCRIPTIONS_SOURCE
      end

      def banner_class=(value)
        unless VALID_BANNER_CLASS_VALUES.include?(value)
          raise InvalidConfigurationValue, "The banner_class provided '#{value}' is " \
            "not one of: #{VALID_BANNER_CLASS_VALUES.join(', ')}"
        end
        @banner_class = value
      end
    end
  end
end
