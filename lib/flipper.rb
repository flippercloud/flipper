require "forwardable"

module Flipper
  extend self
  extend Forwardable

  # Private: The namespace for all instrumented events.
  InstrumentationNamespace = :flipper

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

    result = yield configuration
    refresh_named_instance_accessors
    result
  end

  # Public: Returns Flipper::Configuration instance.
  def configuration
    @configuration ||= Configuration.new
  end

  # Public: Sets Flipper::Configuration instance.
  def configuration=(configuration)
    # need to reset flipper instance if configuration changes
    self.instance = nil
    Thread.current[:__flipper_named_instances__] = nil
    remove_named_instance_accessors
    @configuration = configuration
    refresh_named_instance_accessors
    configuration
  end

  # Public: Default per thread flipper instance if configured. You should not
  # need to use this directly as most of the Flipper::DSL methods are delegated
  # from Flipper module itself. Instead of doing Flipper.instance.enabled?(:search),
  # you can use Flipper.enabled?(:search) for the same result.
  #
  # Returns Flipper::DSL instance.
  def instance
    Thread.current[:flipper_instance] ||= configuration.default
  end

  # Public: Set the flipper instance. It is most common to use the
  # Configuration#default to set this instance, but for things like the test
  # environment, this writer is actually useful.
  def instance=(flipper)
    Thread.current[:flipper_instance] = flipper
  end

  # Public: Returns a stable proxy for a configured named instance.
  def named(name)
    name = normalize_named_instance_name(name)
    named_configuration(name)
    named_instance_proxies_mutex.synchronize do
      named_instance_proxies[name] ||= NamedProxy.new(name)
    end
  end

  # Internal: Returns the current named configuration or raises if missing.
  def named_configuration(name)
    name = normalize_named_instance_name(name)
    configured = configuration.respond_to?(:named_configuration) && configuration.named_configuration(name)
    return configured if configured

    raise NamedInstanceNotFound, "Named instance #{name.inspect} has not been configured"
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
    name = normalize_named_instance_name(name)
    return name if named_instance_accessor_names.include?(name)

    if singleton_class.public_method_defined?(name) ||
        singleton_class.protected_method_defined?(name) ||
        singleton_class.private_method_defined?(name)
      raise InvalidNamedInstanceName, "Named instance #{name.inspect} conflicts with an existing Flipper method"
    end

    name
  end

  private :named_configuration, :named_instance, :reset_named_instances,
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

  def feature_enabled(name)
    Expression.build({ FeatureEnabled: name })
  end

  def feature_disabled(name)
    feature_enabled(name).eq(false)
  end

  # Public: Use this to register a group by name.
  #
  # name - The Symbol name of the group.
  # block - The block that should be used to determine if the group matches a
  #         given actor.
  #
  # Examples
  #
  #   Flipper.register(:admins) { |actor|
  #     actor.respond_to?(:admin?) && actor.admin?
  #   }
  #
  # Returns a Flipper::Group.
  # Raises Flipper::DuplicateGroup if the group is already registered.
  def register(name, &block)
    group = Types::Group.new(name, &block)
    groups_registry.add(group.name, group)
    group
  rescue Registry::DuplicateKey
    raise DuplicateGroup, "Group #{name.inspect} has already been registered"
  end

  # Public: Returns a Set of registered Types::Group instances.
  def groups
    groups_registry.values.to_set
  end

  # Public: Returns a Set of symbols where each symbol is a registered
  # group name. If you just want the names, this is more efficient than doing
  # `Flipper.groups.map(&:name)`.
  def group_names
    groups_registry.keys.to_set
  end

  # Public: Clears the group registry.
  #
  # Returns nothing.
  def unregister_groups
    groups_registry.clear
  end

  # Public: Check if a group exists
  #
  # Returns boolean
  def group_exists?(name)
    groups_registry.key?(name)
  end

  # Public: Fetches a group by name.
  #
  # name - The Symbol name of the group.
  #
  # Examples
  #
  #   Flipper.group(:admins)
  #
  # Returns Flipper::Group.
  def group(name)
    groups_registry.get(name) || Types::Group.new(name)
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
Flipper.configuration
Flipper.groups_registry

module Flipper
  class << self
    private

    def named_instance_proxies
      @named_instance_proxies ||= {}
    end

    def named_instance_proxies_mutex
      @named_instance_proxies_mutex ||= Mutex.new
    end

    def named_instance_accessor_names
      @named_instance_accessor_names ||= Set.new
    end

    def refresh_named_instance_accessors
      return unless @configuration.respond_to?(:named_instance_names)

      @configuration.named_instance_names.each do |name|
        next if named_instance_accessor_names.include?(name)

        validate_named_instance_name!(name)
        define_singleton_method(name) { named(name) }
        named_instance_accessor_names.add(name)
        named_instance_accessor_methods[name] = method(name)
      end
    end

    def remove_named_instance_accessors
      named_instance_accessor_names.each do |name|
        generated_method = named_instance_accessor_methods[name]
        current_method = method(name) if respond_to?(name, true)
        if current_method == generated_method && singleton_class.instance_methods(false).include?(name)
          singleton_class.send(:remove_method, name)
        end
      end
      named_instance_accessor_names.clear
      named_instance_accessor_methods.clear
    end

    def named_instance_accessor_methods
      @named_instance_accessor_methods ||= {}
    end
  end
end

require "flipper/engine" if defined?(Rails)
