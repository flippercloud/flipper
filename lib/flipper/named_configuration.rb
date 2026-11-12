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
      @version = 0
      @version_mutex = Mutex.new
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
      @default = -> {
        Flipper.new(adapter, instrumenter: instrumenter || Instrumenters::Noop)
      }
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
      @version_mutex.synchronize { @version }
    end

    def instrumenter=(instrumenter)
      @instrumenter = instrumenter
      changed!
    end

    # Public: Configure this named instance to use Flipper Cloud.
    #
    # Project credentials are resolved explicitly for this name and never
    # fall back to the default FLIPPER_CLOUD_TOKEN or sync secret.
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
        require "flipper/cloud"
        resolved = resolve_cloud_credentials
        Flipper::Cloud.new(resolved.merge(
          local_adapter: adapter,
          instrumenter: instrumenter || Instrumenters::Noop
        ))
      }
      changed!
      self
    end

    def cloud?
      @cloud
    end

    # Internal: Resolve named credentials with explicit isolation from the
    # existing default Cloud environment variables.
    def resolve_cloud_credentials(credentials = {}, env = ENV)
      return @resolved_cloud_options if @resolved_cloud_options

      prefix = "FLIPPER_CLOUD_#{name.to_s.upcase}"
      token = cloud_value(:token, credentials, env["#{prefix}_TOKEN"])
      sync_secret = cloud_value(:sync_secret, credentials, env["#{prefix}_SYNC_SECRET"])

      if token.nil? || token.empty?
        raise InvalidConfigurationValue,
          "Cloud token for named instance #{name.inspect} is missing; configure :token or #{prefix}_TOKEN"
      end

      resolved = @cloud_options.merge(
        token: token,
        sync_secret: sync_secret
      )
      @resolved_cloud_options = resolved unless credentials.empty?
      resolved
    end

    # Internal: Where to mount this instance's Cloud webhook, or nil when it
    # has nothing to mount (not Cloud, no path, or no sync secret).
    def cloud_webhook_path
      return unless cloud? && cloud_path

      sync_secret = resolve_cloud_credentials[:sync_secret]
      return if sync_secret.nil? || sync_secret == false || sync_secret.empty?

      cloud_path
    end

    # Internal: Apply app-wide Rails settings that were not overridden by the
    # named configuration.
    def inherit_rails_configuration(flipper)
      @memoize = flipper.memoize if @memoize.nil?
      @preload = flipper.preload if @preload.nil?
      @strict = flipper.strict if @strict.nil?
      @actor_limit = flipper.actor_limit if @actor_limit.nil?
      self.instrumenter = flipper.instrumenter if @instrumenter.nil?
      self
    end

    private

    def cloud_value(key, credentials, env_value)
      return @cloud_options[key] if @cloud_options.key?(key)

      credential_value = credentials[key]
      return credential_value unless credential_value.nil?

      env_value
    end

    def changed!
      @version_mutex.synchronize { @version += 1 }
    end
  end
end
