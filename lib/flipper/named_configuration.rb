require 'concurrent/atomic/atomic_fixnum'

module Flipper
  class NamedConfiguration < Configuration
    include Groups

    attr_reader :name, :groups_registry
    attr_accessor :memoize, :preload, :env_key, :strict, :actor_limit, :cloud_path
    attr_reader :instrumenter

    def initialize(name)
      super()
      @name = name
      @groups_registry = Registry.new
      @version = Concurrent::AtomicFixnum.new(0)
      @memoize = nil
      @preload = nil
      @env_key = "flipper_#{name}"
      @strict = nil
      @actor_limit = nil
      @cloud_path = nil
      @instrumenter = nil
      @cloud = false
      @cloud_options = {}
      @resolved_cloud_options = nil
      @warned_missing_cloud_token = false
      @cloud_memory = nil
      @cloud_memory_version = nil
      @cloud_memory_lock = Mutex.new
      @default = -> { local_instance }
    end

    def named(*)
      raise InvalidConfigurationValue, "Named Flipper instances cannot be nested"
    end

    def default(&block)
      if block_given?
        @cloud = false
        @cloud_options = {}
        @resolved_cloud_options = nil
        self.cloud_path = nil
        super
      else
        instance = super
        unless Flipper.send(:claim_instance_owner, instance, self)
          raise InvalidConfigurationValue, "Named instance #{name.inspect} must return a Flipper DSL"
        end

        instance
      end
    end

    def version
      @version.value
    end

    def instrumenter=(instrumenter)
      @instrumenter = instrumenter
      changed!
    end

    # Public: Configure this named instance to use Flipper Cloud.
    #
    # Project credentials are resolved explicitly for this name and never
    # fall back to the default FLIPPER_CLOUD_TOKEN or sync secret. Without a
    # token (development, CI, asset builds), the instance uses its own adapter
    # and warns once, like the default instance without FLIPPER_CLOUD_TOKEN.
    def cloud(options = {})
      options = options.dup
      if options.key?(:local_adapter)
        raise InvalidConfigurationValue, "Use the named adapter configuration instead of :local_adapter"
      end

      self.cloud_path = options.delete(:path) if options.key?(:path)
      self.instrumenter = options.delete(:instrumenter) if options.key?(:instrumenter)
      @cloud = true
      @cloud_options = options
      @resolved_cloud_options = nil
      @default = -> {
        resolved = resolve_cloud_credentials
        unless resolved
          warn_missing_cloud_token
          next local_instance
        end

        require "flipper/cloud"
        Flipper::Cloud.new(resolved.merge(
          instrumenter: instrumenter || Instrumenters::Noop
        ).merge(cloud_adapter_options))
      }
      changed!
      self
    end

    def cloud?
      @cloud
    end

    # Internal: Resolve named credentials with explicit isolation from the
    # existing default Cloud environment variables. Returns nil without a token.
    def resolve_cloud_credentials(credentials = {})
      return @resolved_cloud_options if @resolved_cloud_options

      prefix = "FLIPPER_CLOUD_#{name.to_s.upcase}"
      token = cloud_value(:token, credentials, ENV["#{prefix}_TOKEN"])
      sync_secret = cloud_value(:sync_secret, credentials, ENV["#{prefix}_SYNC_SECRET"])

      return if token.nil? || token.empty?

      resolved = @cloud_options.merge(
        token: token,
        sync_secret: sync_secret
      )
      @resolved_cloud_options = resolved unless credentials.empty?
      resolved
    end

    # Internal: Where to mount this instance's Cloud webhook, or nil when it
    # has nothing to mount (not Cloud, no path, no token, or no sync secret).
    def cloud_webhook_path
      return unless cloud? && cloud_path

      credentials = resolve_cloud_credentials
      return unless credentials

      sync_secret = credentials[:sync_secret]
      return if sync_secret.nil? || sync_secret == false || sync_secret.empty?

      cloud_path
    end

    # Internal: Apply app-wide Rails settings that were not overridden by the
    # named configuration. Preload is not inherited: it would add a query per
    # named instance to every request, even ones that never check its flags.
    def inherit_rails_configuration(flipper)
      @memoize = flipper.memoize if @memoize.nil?
      @preload = false if @preload.nil?
      @strict = flipper.strict if @strict.nil?
      @actor_limit = flipper.actor_limit if @actor_limit.nil?
      self.instrumenter = flipper.instrumenter if @instrumenter.nil?
      self
    end

    private

    def local_instance
      Flipper.new(adapter, instrumenter: instrumenter || Instrumenters::Noop)
    end

    # Reads come from one Memory adapter that every thread shares, like the
    # default Cloud instance, unless FLIPPER_CLOUD_MEMORY_READS is false.
    def cloud_adapter_options
      return { local_adapter: adapter } unless Flipper::Cloud.memory_reads?

      { memory: cloud_memory, adapter_builder: self }
    end

    # One Memory adapter per process for each version of this configuration,
    # so a new adapter or cloud call doesn't read the old adapter's flags.
    def cloud_memory
      @cloud_memory_lock.synchronize do
        current = version
        if @cloud_memory.nil? || @cloud_memory_version != current
          @cloud_memory = Flipper::Cloud::SharedMemory.new
          @cloud_memory_version = current
        end
        @cloud_memory
      end
    end

    def warn_missing_cloud_token
      return if @warned_missing_cloud_token

      @warned_missing_cloud_token = true
      warn "Flipper named instance #{name.inspect} is configured for Cloud but has no " \
        "token (FLIPPER_CLOUD_#{name.to_s.upcase}_TOKEN or flipper.#{name}.cloud_token " \
        "credentials), so it is using its local adapter and not syncing with Cloud."
    end

    def cloud_value(key, credentials, env_value)
      return @cloud_options[key] if @cloud_options.key?(key)

      credential_value = credentials[key]
      return credential_value unless credential_value.nil?

      env_value
    end

    def changed!
      @version.increment
    end
  end
end
