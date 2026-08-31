module Flipper
  class NamedProxy
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def instance
      Flipper.send(:named_instance, name)
    end

    def register(name, &block)
      configuration.register(name, &block)
    end

    def groups
      configuration.groups
    end

    def group_names
      configuration.group_names
    end

    def group_exists?(name)
      configuration.group_exists?(name)
    end

    def group(name)
      configuration.group(name)
    end

    def unregister_groups
      configuration.unregister_groups
    end

    def inspect
      "#<#{self.class.name} name=#{name.inspect}>"
    end

    def respond_to_missing?(method_name, include_private = false)
      return false if method_name == :call

      instance.respond_to?(method_name, include_private) || super
    end

    private

    def configuration
      Flipper.send(:named_configuration, name)
    end

    def method_missing(method_name, *args, **kwargs, &block)
      target = instance
      return super unless target.respond_to?(method_name)

      if kwargs.empty?
        target.public_send(method_name, *args, &block)
      else
        target.public_send(method_name, *args, **kwargs, &block)
      end
    end
  end
end
