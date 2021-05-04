require "flipper/railtie"

module Flipper
  module Cloud
    class Engine < Rails::Engine
      initializer "flipper.cloud", after: :load_config_initializers do |app|
        flipper = Flipper.instance
        next unless flipper.is_a?(Flipper::Cloud::DSL)

        cloud_config = flipper.cloud_configuration

        if cloud_config.sync_method == :webhook
          cloud_app = Flipper::Cloud.app(
            env_key: Flipper.configuration.env_key,
            memoizer_options: { preload: Flipper.configuration.preload }
          )

          app.routes.draw do
            mount cloud_app, at: cloud_config.app_path
          end
        end
      end
    end
  end
end
