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
    groups.add(group.name, group)
    group
  rescue Registry::DuplicateKey
    raise DuplicateGroup, %Q{Group #{name.inspect} has already been registered}
  end

  # Public: Clears the group registry.
  #
  # Returns nothing.
  def self.unregister_groups
    groups.clear
  end

  # Internal: Fetches a group by name.
  #
  # name - The Symbol name of the group.
  #
  # Examples
  #
  #   Flipper.group(:admins)
  #
  # Returns the Flipper::Group if group registered.
  # Raises Flipper::GroupNotRegistered if group is not registered.
  def self.group(name)
    groups.get(name)
  rescue Flipper::Registry::KeyNotFound => e
    raise GroupNotRegistered, "Group #{e.key.inspect} has not been registered"
  end

  # Internal: Registry of all groups.
  def self.groups
    @groups ||= Registry.new
  end

  # Internal: Change the groups registry.
  def self.groups=(registry)
    @groups = registry
  end
end

require 'flipper/adapter'
require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/features'
require 'flipper/gate'
require 'flipper/registry'
require 'flipper/type'
