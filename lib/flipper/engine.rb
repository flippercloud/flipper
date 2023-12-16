module Flipper
  class Engine < Rails::Engine
    paths["config/routes.rb"] = ["lib/flipper/cloud/routes.rb"]

    config.before_configuration do
      config.flipper = ActiveSupport::OrderedOptions.new.update(
        env_key: ENV.fetch('FLIPPER_ENV_KEY', 'flipper'),
        memoize: ENV.fetch('FLIPPER_MEMOIZE', 'true').casecmp('true').zero?,
        preload: ENV.fetch('FLIPPER_PRELOAD', 'true').casecmp('true').zero?,
        instrumenter: ENV.fetch('FLIPPER_INSTRUMENTER', 'ActiveSupport::Notifications').constantize,
        log: ENV.fetch('FLIPPER_LOG', 'true').casecmp('true').zero?,
        cloud_path: "_flipper",
        strict: default_strict_value
      )
    end

    initializer "flipper.properties" do
      ActiveSupport.on_load(:active_record) do
        require "flipper/model/active_record"
        ActiveRecord::Base.include Flipper::Model::ActiveRecord
      end
    end

    initializer "flipper.default", before: :load_config_initializers do |app|
      # Load cloud secrets from Rails credentials
      ENV["FLIPPER_CLOUD_TOKEN"] ||= app.credentials.dig(:flipper, :cloud_token)
      ENV["FLIPPER_CLOUD_SYNC_SECRET"] ||= app.credentials.dig(:flipper, :cloud_sync_secret)

      require 'flipper/cloud' if cloud?

      Flipper.configure do |config|
        if app.config.flipper.strict
          config.use Flipper::Adapters::Strict, app.config.flipper.strict
        end

        config.default do
          if cloud?
            Flipper::Cloud.new(
              local_adapter: config.adapter,
              instrumenter: app.config.flipper.instrumenter,
              memoize: app.config.flipper.memoize
            )
          else
            Flipper.new(config.adapter, {
              instrumenter: app.config.flipper.instrumenter,
              memoize: app.config.flipper.memoize,
            })
          end
        end
      end
    end

    initializer "flipper.log", after: :load_config_initializers do |app|
      flipper = app.config.flipper

      if flipper.log && flipper.instrumenter == ActiveSupport::Notifications
        require "flipper/instrumentation/log_subscriber"
      end
    end

    initializer "flipper.memoizer", after: :load_config_initializers do |app|
      flipper = app.config.flipper

      if flipper.memoize == :poll
        app.middleware.use Flipper::Middleware::Sync
      elsif flipper.memoize
        app.middleware.use Flipper::Middleware::Memoizer, {
          env_key: flipper.env_key,
          preload: flipper.preload,
          if: flipper.memoize.respond_to?(:call) ? flipper.memoize : nil
        }
      end
    end

    def cloud?
      !!ENV["FLIPPER_CLOUD_TOKEN"]
    end

    def self.default_strict_value
      value = ENV["FLIPPER_STRICT"]
      if value.in?(["warn", "raise", "noop"])
        value.to_sym
      elsif value
        Typecast.to_boolean(value) ? :raise : false
      elsif Rails.env.production?
        false
      else
        # Warn for now. Future versions will default to :raise in development and test
        :warn
      end
    end

    def self.deprecated_rails_version?
      Gem::Version.new(Rails.version) < Gem::Version.new(Flipper::NEXT_REQUIRED_RAILS_VERSION)
    end
  end
end
