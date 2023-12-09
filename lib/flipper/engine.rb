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
        cloud_path: "_flipper"
      )
    end

    initializer "flipper.properties" do
      ActiveSupport.on_load(:active_record) do
        require "flipper/model/active_record"
        ActiveRecord::Base.include Flipper::Model::ActiveRecord
      end
    end

    initializer "flipper.default", before: :load_config_initializers do |app|
      require 'flipper/cloud' if cloud?

      Flipper.configure do |config|
        config.default do
          if cloud?
            Flipper::Cloud.new(
              local_adapter: config.adapter,
              instrumenter: app.config.flipper.instrumenter
            )
          else
            Flipper.new(config.adapter, instrumenter: app.config.flipper.instrumenter)
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

      if flipper.memoize
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
  end
end
