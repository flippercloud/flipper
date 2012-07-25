require 'flipper/group'
require 'flipper/switch'

module Flipper
  class Feature
    attr_reader :name
    attr_reader :adapter

    def initialize(name, adapter)
      @name = name
      @adapter = adapter
    end

    def enable(thing = Switch.new)
      if thing.type == :set
        adapter.set_add prefixed_key(thing.key), thing.value
      else
        adapter.write prefixed_key(thing.key), thing.value
      end
    end

    def disable(thing = Switch.new)
      if thing.type == :set
        adapter.set_delete prefixed_key(thing.key), thing.value
      else
        adapter.delete prefixed_key(Switch::Key)
        adapter.delete prefixed_key(Group::Key)
      end
    end

    # true if switch key true
    # thing is..
    #   switch => switch key
    #   group  => group key
    #   else   => true if any enabled groups match actor
    def enabled?(thing = Switch.new)
      switch_value = value(:switch)
      return switch_value if switch_value || thing.is_a?(Switch)
      groups.any? { |group| group.match?(thing) }
    end

    def disabled?(thing = nil)
      !enabled?(thing)
    end

    private

    def prefixed_key(key)
      "#{name}.#{key}"
    end

    def value(key)
      !!adapter.read(prefixed_key(key))
    end

    def members(key)
      adapter.set_members prefixed_key(key)
    end

    def groups
      members(Group::Key).map { |name| Group.get(name) }.compact
    end
  end
end
