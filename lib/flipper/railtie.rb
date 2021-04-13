module Flipper
  class Railtie < Rails::Railtie
    initializer "flipper.memoizer" do |app|
      config = Flipper.configuration

      app.middleware.use Flipper::Middleware::SetupEnv, config.default, env_key: config.env_key

      if config.memoize
        app.middleware.use Flipper::Middleware::Memoizer, {
          env_key: config.env_key,
          preload: config.preload,
          unless: config.memoize_unless
        }
      end
    end

    initializer "flipper.identifier" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.include Flipper::Identifier
      end
    end
  end
end
