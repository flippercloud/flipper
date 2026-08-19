require "flipper"
require "flipper/middleware/setup_env"
require "flipper/middleware/memoizer"
require "flipper/cloud/configuration"
require "flipper/cloud/dsl"
require "flipper/cloud/middleware"
require "flipper/cloud/migrate"

module Flipper
  module Cloud
    # Public: Returns a new Flipper instance with an http adapter correctly
    # configured for flipper cloud.
    #
    # token - The String token for the environment from the website.
    # options - The Hash of options. See Flipper::Cloud::Configuration.
    # block - The block that configuration will be yielded to allowing you to
    #         customize this cloud instance and its adapter.
    def self.new(options = {})
      configuration = Configuration.new(options)
      yield configuration if block_given?
      DSL.new(configuration)
    end

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      memoizer_options = options.fetch(:memoizer_options, {})
      middleware_options = {env_key: env_key}
      middleware_options[:signature_tolerance] = options[:signature_tolerance] if options.key?(:signature_tolerance)

      app = ->(_) { [404, { Rack::CONTENT_TYPE => 'application/json'.freeze }, ['{}'.freeze]] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Middleware::Memoizer, memoizer_options.merge(env_key: env_key)
      builder.use Flipper::Cloud::Middleware, middleware_options
      builder.run app
      klass = self
      app = builder.to_app
      app.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      app
    end

    # Private: Configure Flipper to use Cloud by default
    def self.set_default(instrumenter: nil)
      if ENV["FLIPPER_CLOUD_TOKEN"]
        local_memory = Flipper::Adapters::Memory.new(threadsafe: true)
        local_memory_loaded = false
        local_memory_lock = Mutex.new
        Flipper.configure do |config|
          config.wrap_adapter_store(:flipper_cloud_memory) do |persistent_adapter|
            local_memory_lock.synchronize do
              unless local_memory_loaded
                local_memory.import(persistent_adapter)
                local_memory_loaded = true
              end
            end
            Flipper::Adapters::DualWrite.new(
              local_memory,
              persistent_adapter,
            )
          end
          config.default do
            options = {
              local_adapter: config.adapter,
              local_adapter_memory_backed: true,
            }
            options[:instrumenter] = instrumenter if instrumenter
            self.new(options)
          end
        end
      end
    end
  end
end

Flipper::Cloud.set_default
