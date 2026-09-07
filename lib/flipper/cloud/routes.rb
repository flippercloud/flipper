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

  if !Rails.application.config.flipper.test_help && Flipper.configuration.respond_to?(:named_instance_names)
    Flipper.configuration.named_instance_names.each do |name|
      named = Flipper.configuration.named_configuration(name)
      next unless named.cloud? && named.cloud_path

      cloud_options = named.resolve_cloud_credentials
      sync_secret = cloud_options[:sync_secret]
      next if sync_secret.nil? || sync_secret == false || sync_secret.empty?

      require "flipper/cloud"
      cloud_app = Flipper::Cloud.app(Flipper.named(name),
        env_key: named.env_key,
        memoizer_options: { preload: named.preload }
      )
      cloud_mounts << [named.cloud_path, cloud_app]
    end
  end

  cloud_mounts.sort_by do |path, _|
    normalized_path = path.to_s.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
    -normalized_path.length
  end.each do |path, cloud_app|
    mount cloud_app, at: path
  end
end
