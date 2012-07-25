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
      case thing
      when Flipper::Switch
        @adapter.write "#{@name}.switch", true
      when Flipper::Group
        @adapter.set_add "#{@name}.groups", thing.name
      end
    end

    def disable(thing = Switch.new)
      case thing
      when Flipper::Switch
        @adapter.delete "#{@name}.switch"
        @adapter.delete "#{@name}.groups"
      when Flipper::Group
        @adapter.set_delete "#{@name}.groups", thing.name
      end
    end

    # true if switch key true
    # thing is..
    #   switch => switch key
    #   group  => group key
    #   else   => true if any enabled groups match actor
    def enabled?(thing = Switch.new)
      return true if (switch_value = @adapter.read("#{@name}.switch"))

      case thing
      when Flipper::Switch
        switch_value
      when Flipper::Group
        group_names = @adapter.set_members("#{@name}.groups")
        group_names.include?(thing.name)
      else
        group_names = @adapter.set_members("#{@name}.groups")
        groups = group_names.map { |name| Group.get(name) }.compact
        groups.any? { |group| group.match?(thing) }
      end
    end

    def disabled?(thing = nil)
      !enabled?(thing)
    end
  end
end
