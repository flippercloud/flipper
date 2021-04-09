# Default routes loaded by Flipper::Cloud::Engine
Rails.application.routes.draw do
  config = Flipper::Cloud::Engine.config.flipper

  if config.cloud.sync_method == :webhook
    # FIXME: does it make sense to provide a Rails-specific config to fetch the instance? Or what should this be?
    flipper = Flipper.instance

    app = Flipper::Cloud.app(flipper,
      env_key: config.env_key,
      memoizer_options: config.momoizer
    )

    mount app, at: config.cloud.path
  end
end
