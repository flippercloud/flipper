require "flipper/railtie"

module Flipper
  module Cloud
    class Engine < Rails::Engine
      config.before_configuration do
        config.flipper.cloud_path = "_flipper"
      end

      initializer "flipper.cloud.default", before: :load_config_initializers do |app|
        Flipper.configure do |config|
          config.default do
            if ENV["FLIPPER_CLOUD_TOKEN"]
              Flipper::Cloud.new(
                local_adapter: config.adapter,
                instrumenter: app.config.flipper.instrumenter
              )
            else
              warn "Missing FLIPPER_CLOUD_TOKEN environment variable. Disabling Flipper::Cloud."
              Flipper.new(config.adapter)
            end
          end
        end
      end

      initializer "flipper.cloud.webhook", after: :load_config_initializers do |app|
        if ENV["FLIPPER_CLOUD_SYNC_SECRET"]
          config = app.config.flipper

          cloud_app = Flipper::Cloud.app(
            env_key: config.env_key,
            memoizer_options: { preload: config.preload }
          )

          app.routes.draw do
            mount cloud_app, at: config.cloud_path
          end
        end
      end
    end
  end
end
