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
  #     config.default { ... }
  #   end
  #
  # Yields Flipper::Configuration instance.
  def configure
    yield configuration if block_given?
  end

  # Public: Returns Flipper::Configuration instance.
  def configuration
    @configuration ||= Configuration.new
  end

  # Public: Sets Flipper::Configuration instance.
  def configuration=(configuration)
    @configuration = configuration
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

  # Public: All the methods delegated to instance. These should match the
  # interface of Flipper::DSL.
  def_delegators :instance,
                 :enabled?, :enable, :disable, :bool, :boolean,
                 :enable_actor, :disable_actor, :actor,
                 :enable_group, :disable_group,
                 :enable_percentage_of_actors, :disable_percentage_of_actors,
                 :actors, :percentage_of_actors,
                 :enable_percentage_of_time, :disable_percentage_of_time,
                 :time, :percentage_of_time,
                 :features, :feature, :[], :preload, :preload_all,
                 :add, :remove, :import

  # Public: Use this to register a group by name.
  #
  # name - The Symbol name of the group.
  # block - The block that should be used to determine if the group matches a
  #         given thing.
  #
  # Examples
  #
  #   Flipper.register(:admins) { |thing|
  #     thing.respond_to?(:admin?) && thing.admin?
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
require 'flipper/configuration'
require 'flipper/adapter'
require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/gate'
require 'flipper/registry'
require 'flipper/type'
require 'flipper/typecast'
