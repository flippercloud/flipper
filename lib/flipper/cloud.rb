require "flipper"
require "flipper/middleware/setup_env"
require "flipper/middleware/memoizer"
require "flipper/cloud/configuration"
require "flipper/cloud/dsl"
require "flipper/cloud/middleware"
require "flipper/cloud/migrate"
require "flipper/adapters/sync"

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
        configuration = Flipper.configuration
        context = default_context(configuration)
        local_memory = context.fetch(:memory)
        Flipper.configure do |config|
          config.wrap_adapter_store(:flipper_cloud_memory) do |persistent_adapter|
            context.fetch(:state).lock.synchronize do
              unless context[:loaded]
                local_memory.import(persistent_adapter)
                context[:loaded] = true
              end
            end
            if !ENV.fetch("FLIPPER_CLOUD_SYNC_SECRET", "").empty? && !memory_store?(persistent_adapter)
              sync_interval = [
                Flipper::Typecast.to_float(ENV.fetch("FLIPPER_CLOUD_SYNC_INTERVAL", 10)),
                Flipper::Poller::MINIMUM_POLL_INTERVAL,
              ].max
              Flipper::Adapters::Sync.new(
                local_memory,
                persistent_adapter,
                interval: sync_interval,
                interval_state: context.fetch(:state),
              )
            else
              Flipper::Adapters::DualWrite.new(
                local_memory,
                persistent_adapter,
              )
            end
          end
          config.default do
            options = {
              local_adapter: config.adapter,
              synchronization_state: context.fetch(:state),
            }
            options[:instrumenter] = instrumenter if instrumenter
            self.new(options)
          end
        end
      end
    end

    def self.default_context(configuration)
      context = configuration.instance_variable_get(:@flipper_cloud_default_context)
      return context if context

      context = {
        memory: Flipper::Adapters::Memory.new(threadsafe: true),
        loaded: false,
        state: Flipper::Adapters::Sync::IntervalSynchronizer::State.new(synced: true),
      }
      configuration.instance_variable_set(:@flipper_cloud_default_context, context)
      context
    end
    private_class_method :default_context

    def self.memory_store?(adapter)
      until adapter.is_a?(Flipper::Adapters::Memory) || !adapter.respond_to?(:adapter)
        nested_adapter = adapter.adapter
        break if nested_adapter.equal?(adapter)
        adapter = nested_adapter
      end
      adapter.is_a?(Flipper::Adapters::Memory)
    end
    private_class_method :memory_store?
  end
end

Flipper::Cloud.set_default
