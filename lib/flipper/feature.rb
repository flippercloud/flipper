module Flipper
  class Feature
    attr_reader :name

    def initialize(name, adapter)
      @name = name
      @adapter = adapter
    end

    def enable(thing = nil)
      case thing
      when nil
        @adapter.write "#{@name}.boolean", true
      when Flipper::Group
        @adapter.set_add "#{@name}.groups", thing.name
      end
    end

    def disable(thing = nil)
      case thing
      when nil
        @adapter.delete "#{@name}.boolean"
        @adapter.delete "#{@name}.groups"
      when Flipper::Group
        @adapter.set_delete "#{@name}.groups", thing.name
      end
    end

    # thing is..
    #   nil   => boolean key
    #   group => group key
    #   else  =>
    #     - true if boolean key true
    #     - true if any enabled groups match actor
    def enabled?(thing = nil)
      boolean_flip = @adapter.read("#{@name}.boolean")

      if boolean_flip || thing.nil?
        return boolean_flip
      end

      if thing.is_a?(Flipper::Group)
        group_names = @adapter.set_members("#{@name}.groups")
        return group_names.include?(thing.name)
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
