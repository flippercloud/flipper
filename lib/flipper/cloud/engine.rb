require "flipper/railtie"

module Flipper
  module Cloud
    class Engine < Rails::Engine
      paths["config/routes.rb"] = ["lib/flipper/cloud/routes.rb"]

      config.before_configuration do
        config.flipper.cloud = ActiveSupport::InheritableOptions.new(
          sync_method: default_cloud_sync_method,
          path: '_flipper'
        )
      end

      def default_cloud_sync_method
        ENV["FLIPPER_CLOUD_SYNC_METHOD"]&.to_sym || (Rails.env.production? ? :webhook : :poll)
      end
    end
  end
end
