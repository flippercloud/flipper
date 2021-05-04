module Flipper
  class Railtie < Rails::Railtie
    config.before_configuration do
      config.flipper = ActiveSupport::OrderedOptions.new.update(
        env_key: "flipper",
        memoize: true,
        preload: true
      )
    end

    initializer "flipper.memoizer", after: :load_config_initializers do |app|
      config = app.config.flipper

      if config.memoize
        app.middleware.use Flipper::Middleware::Memoizer, {
          env_key: config.env_key,
          preload: config.preload,
          if: config.memoize.respond_to?(:call) ? config.memoize : nil
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
