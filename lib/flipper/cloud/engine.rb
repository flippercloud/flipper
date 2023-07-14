require "flipper/railtie"

module Flipper
  module Cloud
    class Engine < Rails::Engine
      paths["config/routes.rb"] = ["lib/flipper/cloud/routes.rb"]

      config.before_configuration do
        config.flipper.cloud_path = "_flipper"
      end

      initializer "flipper.cloud.default", before: :load_config_initializers do |app|
        if ENV["FLIPPER_CLOUD_TOKEN"]
          Flipper.configure do |config|
            config.default do
              Flipper::Cloud.new(
                local_adapter: config.adapter,
                instrumenter: app.config.flipper.instrumenter
              )
            end
          end
        end
      end
    end
  end
end
