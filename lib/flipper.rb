require "forwardable"
require "flipper/groups"

module Flipper
  extend self
  extend Forwardable
  extend Groups

  # Private: The namespace for all instrumented events.
  InstrumentationNamespace = :flipper

  # Public: Feature keys starting with this are reserved for data Flipper
  # stores next to features, like the sync version.
  RESERVED_KEY_PREFIX = "__flipper".freeze

  # Public: Is this feature key reserved for Flipper's own data?
  def reserved_key?(key)
    key.to_s.start_with?(RESERVED_KEY_PREFIX)
  end

  # Public: Start here. Given an adapter returns a handy DSL to all the flipper
  # goodness. To see supported options, check out dsl.rb.
  def new(adapter, options = {})
    DSL.new(adapter, options)
  end

  # Public: Configure flipper.
  #
  #   Flipper.configure do |config|
  #     config.adapter { ... }
  #   end
  #
  # Yields Flipper::Configuration instance.
  def configure
    return unless block_given?

    configured = configuration
    begin
      yield configured
    ensure
      refresh_named_instance_accessors(configured)
    end
  end

  # Public: Returns Flipper::Configuration instance.
  def configuration
    return @configuration if @configuration

    @named_instance_lifecycle_mutex.synchronize do
      @configuration ||= Configuration.new
    end
  end

  # Public: Sets Flipper::Configuration instance.
  def configuration=(configuration)
    @named_instance_lifecycle_mutex.synchronize do
      previous_configuration = @configuration
      previous_instance = Thread.current[:flipper_instance]
      previous_named_instances = Thread.current[:__flipper_named_instances__]
      validate_named_instance_accessors!(configuration)
      committed = false

      begin
        # need to reset flipper instances if configuration changes
        Thread.current[:flipper_instance] = nil
        Thread.current[:__flipper_named_instances__] = nil
        remove_named_instance_accessors_without_lock
        @configuration = configuration
        refresh_named_instance_accessors_without_lock(configuration)
        committed = true
      ensure
        unless committed
          begin
            remove_named_instance_accessors_without_lock
            @configuration = previous_configuration
            refresh_named_instance_accessors_without_lock(previous_configuration)
          ensure
            Thread.current[:flipper_instance] = previous_instance
            Thread.current[:__flipper_named_instances__] = previous_named_instances
          end
        end
      end

      configuration
    end
  end

  # Public: Default per thread flipper instance if configured. You should not
  # need to use this directly as most of the Flipper::DSL methods are delegated
  # from Flipper module itself. Instead of doing Flipper.instance.enabled?(:search),
  # you can use Flipper.enabled?(:search) for the same result.
  #
  # Returns Flipper::DSL instance.
  def instance
    Thread.current[:flipper_instance] ||= begin
      flipper = configuration.default
      claim_instance_owner(flipper, Flipper)
      flipper
    end
  end

  # Public: Set the flipper instance. It is most common to use the
  # Configuration#default to set this instance, but for things like the test
  # environment, this writer is actually useful.
  def instance=(flipper)
    claim_instance_owner(flipper, Flipper) if flipper
    Thread.current[:flipper_instance] = flipper
  end

  # Public: Returns a stable proxy for a configured named instance.
  def named(name)
    name = normalize_named_instance_name(name)
    named_configuration(name)
    @named_instance_proxies_mutex.synchronize do
      @named_instance_proxies[name] ||= NamedProxy.new(name)
    end
  end

  # Internal: Returns the current named configuration or raises if missing.
  def named_configuration(name)
    name = normalize_named_instance_name(name)
    configured = configuration.respond_to?(:named_configuration) && configuration.named_configuration(name)
    return configured if configured

    raise NamedInstanceNotFound, "Named instance #{name.inspect} has not been configured"
  end

  # Internal: Named configurations, or none for custom configuration objects
  # that don't support named instances.
  def named_configurations(config = configuration)
    config.respond_to?(:named_configurations) ? config.named_configurations : []
  end

  # Internal: Returns the per-thread DSL for a configured named instance.
  def named_instance(name)
    configured = named_configuration(name)
    instances = Thread.current[:__flipper_named_instances__] ||= {}
    cached = instances[name]

    if cached && cached[:configuration].equal?(configured) && cached[:version] == configured.version
      cached[:instance]
    else
      loop do
        version = configured.version
        instance = configured.default
        next unless version == configured.version

        instances[name] = {
          configuration: configured,
          version: version,
          instance: instance,
        }
        return instance
      end
    end
  end

  # Internal: Reset named DSL caches for the current thread.
  def reset_named_instances
    Thread.current[:__flipper_named_instances__] = nil
  end

  # Internal: Normalize and validate a named instance name.
  def normalize_named_instance_name(name)
    unless name.is_a?(String) || name.is_a?(Symbol)
      raise InvalidNamedInstanceName, "Named instance name must be a String or Symbol"
    end

    normalized = name.to_s
    unless normalized.match?(/\A[a-z_][a-z0-9_]*\z/)
      raise InvalidNamedInstanceName, "Named instance #{name.inspect} must use lowercase snake case"
    end

    normalized.to_sym
  end

  # Internal: Reject names that would replace Flipper's existing API.
  def validate_named_instance_name!(name)
    @named_instance_lifecycle_mutex.synchronize do
      validate_named_instance_name_without_lock!(name)
    end
  end

  private :named_configuration, :named_configurations, :named_instance, :reset_named_instances,
          :normalize_named_instance_name, :validate_named_instance_name!

  # Public: All the methods delegated to instance. These should match the
  # interface of Flipper::DSL.
  def_delegators :instance,
                 :enabled?, :enable, :disable,
                 :enable_expression, :disable_expression,
                 :expression, :add_expression, :remove_expression,
                 :enable_actor, :disable_actor,
                 :enable_group, :disable_group,
                 :enable_percentage_of_actors, :disable_percentage_of_actors,
                 :enable_percentage_of_time, :disable_percentage_of_time,
                 :features, :feature, :[], :preload, :preload_all,
                 :adapter, :adapter_stack, :add, :exist?, :remove, :import, :export,
                 :memoize=, :memoizing?, :read_only?,
                 :sync, :sync_secret # For Flipper::Cloud. Will error for OSS Flipper.

  def any(*args)
    Expression.build({ Any: args.flatten })
  end

  def all(*args)
    Expression.build({ All: args.flatten })
  end

  def constant(value)
    Expression.build(value)
  end

  def property(name)
    Expression.build({ Property: name })
  end

  def string(value)
    Expression.build({ String: value })
  end

  def number(value)
    Expression.build({ Number: value })
  end

  def boolean(value)
    Expression.build({ Boolean: value })
  end

  def random(max)
    Expression.build({ Random: max })
  end

  def now
    Expression.build({ Now: [] })
  end

  def time(value)
    Expression.build({ Time: value })
  end

  def semver(value)
    Expression.build({ SemVer: value })
  end

  def feature_enabled(name)
    Expression.build({ FeatureEnabled: name })
  end

  def feature_disabled(name)
    feature_enabled(name).eq(false)
  end

  # Internal: Registry of all groups_registry.
  def groups_registry
    @groups_registry ||= Registry.new
  end

  # Internal: Change the groups_registry registry.
  def groups_registry=(registry)
    @groups_registry = registry
  end
end

require 'flipper/actor'
require 'flipper/adapter'
require 'flipper/adapters/wrapper'
require 'flipper/adapters/actor_limit'
require 'flipper/adapters/instrumented'
require 'flipper/adapters/memoizable'
require 'flipper/adapters/memory'
require 'flipper/adapters/strict'
require 'flipper/adapter_builder'
require 'flipper/registry'
require 'flipper/configuration'
require 'flipper/named_configuration'
require 'flipper/named_proxy'
require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/gate'
require 'flipper/instrumenters/memory'
require 'flipper/instrumenters/noop'
require 'flipper/identifier'
require 'flipper/middleware/memoizer'
require 'flipper/middleware/setup_env'
require 'flipper/poller'
require 'flipper/sync_version'
require 'flipper/expression'
require 'flipper/type'
require 'flipper/types/actor'
require 'flipper/types/boolean'
require 'flipper/types/group'
require 'flipper/types/percentage'
require 'flipper/types/percentage_of_actors'
require 'flipper/types/percentage_of_time'
require 'flipper/typecast'
require 'flipper/version'

# Eagerly initialize memoized module state while loading is still
# single-threaded (require/autoload hold a per-feature lock). This avoids a
# check-then-set race on the `||=` memoization if two threads were to first
# touch Flipper concurrently during a parallel boot.
module Flipper
  @named_instance_proxies = {}
  @named_instance_proxies_mutex = Mutex.new
  @named_instance_accessor_methods = {}
  @named_instance_lifecycle_mutex = Mutex.new

  class << self
    private

    def refresh_named_instance_accessors(configuration)
      @named_instance_lifecycle_mutex.synchronize do
        return unless @configuration.equal?(configuration)

        refresh_named_instance_accessors_without_lock(configuration)
      end
    end

    def refresh_named_instance_accessors_without_lock(configuration)
      validate_named_instance_accessors!(configuration)

      named_configurations(configuration).map(&:name).each do |name|
        next if generated_named_instance_accessor?(name)

        proxy = named(name)
        Thread.handle_interrupt(Exception => :never) do
          define_singleton_method(name) { proxy }
          @named_instance_accessor_methods[name] = method(name)
        end
      end
    end

    def remove_named_instance_accessors_without_lock
      @named_instance_accessor_methods.keys.each do |name|
        remove_named_instance_accessor_without_lock(name)
      end
    end

    def remove_named_instance_accessor_without_lock(name)
      singleton_class.send(:remove_method, name) if generated_named_instance_accessor?(name)
      @named_instance_accessor_methods.delete(name)
    end

    def validate_named_instance_accessors!(configuration)
      named_configurations(configuration).each do |named|
        validate_named_instance_name_without_lock!(named.name)
      end
    end

    def validate_named_instance_name_without_lock!(name)
      name = normalize_named_instance_name(name)
      return name if generated_named_instance_accessor?(name)

      if singleton_class.public_method_defined?(name) ||
          singleton_class.protected_method_defined?(name) ||
          singleton_class.private_method_defined?(name)
        raise InvalidNamedInstanceName, "Named instance #{name.inspect} conflicts with an existing Flipper method"
      end

      name
    end

    def generated_named_instance_accessor?(name)
      generated_method = @named_instance_accessor_methods[name]
      return false unless generated_method

      current_method = method(name) if respond_to?(name, true)
      current_method == generated_method
    end

    def publish_named_configuration(configuration, name, named_configuration)
      @named_instance_lifecycle_mutex.synchronize do
        active = @configuration.equal?(configuration)
        validate_named_instance_name_without_lock!(name) if active
        committed = false

        begin
          configuration.send(:publish_named_configuration, name, named_configuration)
          refresh_named_instance_accessors_without_lock(configuration) if active
          committed = true
        ensure
          unless committed
            configuration.send(:remove_named_configuration, name, named_configuration)
            remove_named_instance_accessor_without_lock(name) if active
          end
        end
      end
    end

    # Claims a DSL for the default instance (owner Flipper) or a named
    # configuration. Returns false when the instance isn't a Flipper DSL.
    def claim_instance_owner(instance, owner)
      dsl = unwrap_flipper_dsl(instance)
      return false unless dsl

      @named_instance_lifecycle_mutex.synchronize do
        dsl.send(:claim_instance_owner, owner)
      end
      true
    end

    def unwrap_flipper_dsl(instance)
      return instance if instance.is_a?(DSL)
      return unless defined?(Delegator) && instance.is_a?(Delegator)

      seen = Set.new
      while instance.is_a?(Delegator)
        return if seen.include?(instance.object_id)

        seen.add(instance.object_id)
        instance = instance.__getobj__
      end

      instance if instance.is_a?(DSL)
    end
  end
end

Flipper.configuration
Flipper.groups_registry

require "flipper/engine" if defined?(Rails)
