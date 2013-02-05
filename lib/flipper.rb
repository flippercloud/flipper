module Flipper
  # Private: The namespace for all instrumented events.
  InstrumentationNamespace = :flipper

  def self.new(*args)
    DSL.new(*args)
  end

  def self.groups
    @groups ||= Registry.new
  end

  def self.groups=(registry)
    @groups = registry
  end

  def self.register(name, &block)
    group = Types::Group.new(name, &block)
    groups.add(group.name, group)
    group
  rescue Registry::DuplicateKey
    raise DuplicateGroup, %Q{Group #{name.inspect} has already been registered}
  end

  def self.group(name)
    groups.get(name)
  rescue Flipper::Registry::KeyNotFound => e
    raise GroupNotRegistered, "Group #{e.key.inspect} has not been registered"
  end
end

require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/gate'
require 'flipper/registry'
require 'flipper/toggle'
require 'flipper/type'
