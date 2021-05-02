# Default routes loaded by Flipper::Cloud::Engine
Rails.application.routes.draw do
  config = Flipper.configuration
  cloud_config = config.default.cloud_configuration

  app = Flipper::Cloud.app(
    env_key: config.env_key,
    memoizer_options: { preload: config.preload }
  )

  mount app, at: cloud_config.app_path if cloud_config.sync_method == :webhook
end
