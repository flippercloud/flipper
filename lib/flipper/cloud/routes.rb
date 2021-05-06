# Default routes loaded by Flipper::Cloud::Engine
Rails.application.routes.draw do
  if ENV["FLIPPER_CLOUD_TOKEN"] && ENV["FLIPPER_CLOUD_SYNC_SECRET"]
    config = Rails.application.config.flipper

    cloud_app = Flipper::Cloud.app(
      env_key: config.env_key,
      memoizer_options: { preload: config.preload }
    )

    mount cloud_app, at: config.cloud_path
  end
end
