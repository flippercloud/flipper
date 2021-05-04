require "flipper/railtie"

module Flipper
  module Cloud
    class Engine < Rails::Engine
      config.before_configuration do
        config.flipper = ActiveSupport::OrderedOptions.new.update(
          cloud_path: "_flipper"
        )
      end

      initializer "flipper.cloud", after: :load_config_initializers do |app|
        if ENV["FLIPPER_CLOUD_TOKEN"] && ENV["FLIPPER_CLOUD_SYNC_SECRET"]
          cloud_app = Flipper::Cloud.app(
            env_key: Flipper.configuration.env_key,
            memoizer_options: { preload: Flipper.configuration.preload }
          )

          app.routes.draw do
            mount cloud_app, at: app.config.flipper.cloud_path
          end
        end
      end
    end
  end
end
