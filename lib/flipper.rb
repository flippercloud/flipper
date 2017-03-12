module Flipper
  # Private: The namespace for all instrumented events.
  InstrumentationNamespace = :flipper

  # Public: Start here. Given an adapter returns a handy DSL to all the flipper
  # goodness. To see supported options, check out dsl.rb.
  def self.new(adapter, options = {})
    DSL.new(adapter, options)
  end

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
  def self.register(name, &block)
    group = Types::Group.new(name, &block)
    groups_registry.add(group.name, group)
    group
  rescue Registry::DuplicateKey
    raise DuplicateGroup, "Group #{name.inspect} has already been registered"
  end

  # Public: Returns a Set of registered Types::Group instances.
  def self.groups
    groups_registry.values.to_set
  end

  # Public: Returns a Set of symbols where each symbol is a registered
  # group name. If you just want the names, this is more efficient than doing
  # `Flipper.groups.map(&:name)`.
  def self.group_names
    groups_registry.keys.to_set
  end

  # Public: Clears the group registry.
  #
  # Returns nothing.
  def self.unregister_groups
    groups_registry.clear
  end

  # Public: Check if a group exists
  #
  # Returns boolean
  def self.group_exists?(name)
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
  def self.group(name)
    groups_registry.get(name) || Types::Group.new(name)
  end

  # Internal: Registry of all groups_registry.
  def self.groups_registry
    @groups_registry ||= Registry.new
  end

  # Internal: Change the groups_registry registry.
  def self.groups_registry=(registry)
    @groups_registry = registry
  end
end

require 'flipper/adapter'
require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/gate'
require 'flipper/registry'
require 'flipper/type'
require 'flipper/typecast'
