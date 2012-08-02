require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/gate'
require 'flipper/registry'
require 'flipper/toggle'
require 'flipper/type'

module Flipper
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
    raise DuplicateGroup, %Q{Group named "#{name}" is already registered}
  end

  def self.group(name)
    groups.get(name)
  end
end
