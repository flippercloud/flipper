require 'securerandom'
require 'active_support/gem_version'
require 'active_support/notifications'
require 'active_support/log_subscriber'

module Flipper
  module Instrumentation
    class LogSubscriber < ::ActiveSupport::LogSubscriber
      # Logs a feature operation.
      #
      # Example Output
      #
      #   flipper[:search].enabled?(user)
      #   # Flipper feature(search) enabled? false (1.2ms)  [ actors=... ]
      #
      # Returns nothing.
      def feature_operation(event)
        return unless logger.debug?

        feature_name = event.payload[:feature_name]
        gate_name = event.payload[:gate_name]
        operation = event.payload[:operation]
        result = event.payload[:result]

        description = "Flipper feature(#{feature_name}) #{operation} #{result.inspect}"

        details = if event.payload.key?(:actors)
          "actors=#{event.payload[:actors].inspect}"
        else
          "thing=#{event.payload[:thing].inspect}"
        end

        details += " gate_name=#{gate_name}" unless gate_name.nil?

        name = '%s (%.1fms)' % [description, event.duration]
        debug "  #{color_name(name)}  [ #{details} ]"
      end

      # Logs an adapter operation. If operation is for a feature, then that
      # feature is included in log output.
      #
      # Example Output
      #
      #   # log output for adapter operation with feature
      #   # Flipper feature(search) adapter(memory) enable  (0.0ms)  [ result=...]
      #
      #   # log output for adapter operation with no feature
      #   # Flipper adapter(memory) features (0.0ms)  [ result=... ]
      #
      # Returns nothing.
      def adapter_operation(event)
        return unless logger.debug?

        feature_name = event.payload[:feature_name]
        adapter_name = event.payload[:adapter_name]
        operation = event.payload[:operation]
        result = event.payload[:result]

        description = String.new('Flipper ')
        description << "feature(#{feature_name}) " unless feature_name.nil?
        description << "adapter(#{adapter_name}) "
        description << "#{operation} "

        details = "result=#{result.inspect}"

        name = '%s (%.1fms)' % [description, event.duration]
        debug "  #{color_name(name)}  [ #{details} ]"
      end

      def logger
        self.class.logger
      end

      def self.attach
        attach_to InstrumentationNamespace
      end

      def self.detach
        # Rails 5.2 doesn't support this, that's fine
        detach_from InstrumentationNamespace if respond_to?(:detach_from)
      end

      private

      # Rails 7.1 changed the signature of this function.
      COLOR_OPTIONS = if Gem::Requirement.new(">=7.1").satisfied_by?(ActiveSupport.gem_version)
        { bold: true }.freeze
      else
        true
      end
      private_constant :COLOR_OPTIONS

      def color_name(name)
        color(name, CYAN, COLOR_OPTIONS)
      end
    end
  end

  Instrumentation::LogSubscriber.attach
end
