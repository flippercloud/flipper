module Flipper
  class Railtie < Rails::Railtie
    initializer "flipper.memoizer" do |app|
      config = Flipper.configuration

      if config.memoize
        app.middleware.use Flipper::Middleware::Memoizer, {
          env_key: config.env_key,
          preload: config.preload,
          if: config.memoize.is_a?(Proc) ? config.memoize : nil
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
