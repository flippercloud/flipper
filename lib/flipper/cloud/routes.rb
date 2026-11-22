# Default routes loaded by Flipper::Cloud::Engine
Rails.application.routes.draw do
  cloud_mounts = []

  if ENV["FLIPPER_CLOUD_TOKEN"] && !ENV.fetch("FLIPPER_CLOUD_SYNC_SECRET", "").empty?
    require 'flipper/cloud'
    config = Rails.application.config.flipper

    cloud_app = Flipper::Cloud.app(nil,
      env_key: config.env_key,
      memoizer_options: { preload: config.preload }
    )

    cloud_mounts << [config.cloud_path, cloud_app]
  end

  unless Rails.application.config.flipper.test_help
    Flipper.send(:named_configurations).each do |named|
      path = named.cloud_webhook_path
      next unless path

      require "flipper/cloud"
      cloud_app = Flipper::Cloud.app(Flipper.named(named.name),
        env_key: named.env_key,
        memoizer_options: { preload: named.preload }
      )
      cloud_mounts << [path, cloud_app]
    end
  end

  cloud_mounts.sort_by do |path, _|
    -Flipper::Engine.normalize_cloud_path(path).length
  end.each do |path, cloud_app|
    mount cloud_app, at: path
  end
end
