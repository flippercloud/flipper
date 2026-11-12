module Flipper
  # Internal: Group registration for anything that has a groups_registry. The
  # Flipper module and each named instance configuration share it.
  module Groups
    # Public: Use this to register a group by name.
    #
    # name - The Symbol name of the group.
    # block - The block that should be used to determine if the group matches a
    #         given actor.
    #
    # Examples
    #
    #   Flipper.register(:admins) { |actor|
    #     actor.respond_to?(:admin?) && actor.admin?
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
  end
end
