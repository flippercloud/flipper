require 'flipper/dsl'
require 'flipper/errors'
require 'flipper/feature'
require 'flipper/gate'
require 'flipper/registry'
require 'flipper/toggle'
require 'flipper/type'

module Flipper
  def groups
    @groups ||= Registry.new
  end

  def groups=(registry)
    @groups = registry
  end

  def register(name, &block)
    group = Types::Group.new(name, &block)
    groups.add(group.name, group)
    group
  rescue Registry::DuplicateKey
    raise DuplicateGroup, %Q{Group named "#{name}" is already registered}
  end

  def group(name)
    groups.get(name)
  end

  extend self
end
