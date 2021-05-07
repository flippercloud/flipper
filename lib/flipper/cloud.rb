require "flipper"
require "flipper/middleware/setup_env"
require "flipper/middleware/memoizer"
require "flipper/cloud/configuration"
require "flipper/cloud/dsl"
require "flipper/cloud/middleware"
require "flipper/cloud/engine" if defined?(Rails::Engine)

module Flipper
  module Cloud
    # Public: Returns a new Flipper instance with an http adapter correctly
    # configured for flipper cloud.
    #
    # token - The String token for the environment from the website.
    # options - The Hash of options. See Flipper::Cloud::Configuration.
    # block - The block that configuration will be yielded to allowing you to
    #         customize this cloud instance and its adapter.
    def self.new(options = {}, deprecated_options = {})
      if options.is_a?(String)
        warn "`Flipper::Cloud.new(token)` is deprecated. Use `Flipper::Cloud.new(token: token)` " +
          "or set the `FLIPPER_CLOUD_TOKEN` environment variable.\n" +
          caller[0]
        options = deprecated_options.merge(token: options)
      end

      configuration = Configuration.new(options)
      yield configuration if block_given?
      DSL.new(configuration)
    end

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      memoizer_options = options.fetch(:memoizer_options, {})

      app = ->(_) { [404, { 'Content-Type'.freeze => 'application/json'.freeze }, ['{}'.freeze]] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Middleware::Memoizer, memoizer_options.merge(env_key: env_key)
      builder.use Flipper::Cloud::Middleware, env_key: env_key
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      builder
    end

    # Private: Configure Flipper to use Cloud by default
    def self.set_default
      Flipper.configure do |config|
        config.default do
          if ENV["FLIPPER_CLOUD_TOKEN"]
            self.new(local_adapter: config.adapter)
          else
            warn "Missing FLIPPER_CLOUD_TOKEN environment variable. Disabling Flipper::Cloud."
            Flipper.new(config.adapter)
          end
        end
      end
    end
  end
end

Flipper::Cloud.set_default
