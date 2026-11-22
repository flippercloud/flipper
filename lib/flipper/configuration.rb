require 'concurrent/map'

module Flipper
  class Configuration
    def initialize(options = {})
      @builder = AdapterBuilder.new { store Flipper::Adapters::Memory }
      @default = -> { Flipper.new(@builder.to_adapter) }
      @named_configurations = Concurrent::Map.new
    end

    # The default adapter to use.
    #
    # Pass a block to assign the adapter, and invoke without a block to
    # return the configured adapter instance.
    #
    #   Flipper.configure do |config|
    #     config.adapter # => instance of default Memory adapter
    #
    #     # Configure it to use the ActiveRecord adapter
    #     config.adapter do
    #       require "flipper/adapters/active_record"
    #       Flipper::Adapters::ActiveRecord.new
    #     end
    #
    #     config.adapter # => instance of ActiveRecord adapter
    #  end
    #
    def adapter(&block)
      if block_given?
        result = @builder.store(block)
        changed!
        result
      else
        @builder.to_adapter
      end
    end

    # Internal: Builds a new storage adapter, without the adapters added with
    # #use. Flipper::Cloud uses it and #wrap to put Memory in front of storage.
    def build_store
      @builder.build_store
    end

    # Internal: Wraps adapter with the adapters added with #use.
    def wrap(adapter)
      @builder.wrap(adapter)
    end

    # An adapter to use to augment the primary storage adapter. See `AdapterBuilder#use`
    if RUBY_VERSION >= '3.0'
      def use(klass, *args, **kwargs, &block)
        result = @builder.use(klass, *args, **kwargs, &block)
        changed!
        result
      end
    else
      def use(klass, *args, &block)
        result = @builder.use(klass, *args, &block)
        changed!
        result
      end
    end

    # Controls the default instance for flipper. When used with a block it
    # assigns a new default block to use to generate an instance. When used
    # without a block, it performs a block invocation and returns the result.
    #
    #   configuration = Flipper::Configuration.new
    #   configuration.default # => Flipper::DSL instance using Memory adapter
    #
    #   # sets the default block to generate a new instance using ActiveRecord adapter
    #   configuration.default do
    #     require "flipper/adapters/active_record"
    #     Flipper.new(Flipper::Adapters::ActiveRecord.new)
    #   end
    #
    #   configuration.default # => Flipper::DSL instance using ActiveRecord adapter
    #
    # Returns result of default block invocation if called without block. If
    # called with block, assigns the default block.
    def default(&block)
      if block_given?
        @default = block
        changed!
        block
      else
        @default.call
      end
    end

    # Public: Configure a named Flipper instance. Calling it again with the
    # same name reopens that instance's configuration, like calling adapter
    # again replaces the adapter.
    #
    #   config.named(:cross_app) do |cross_app|
    #     cross_app.adapter { ... }
    #   end
    #
    # name - Lowercase snake-case name used by Flipper.named and Flipper.<name>.
    # block - Configuration block yielded a Flipper::NamedConfiguration.
    #
    # Returns the named configuration.
    def named(name)
      name = Flipper.send(:normalize_named_instance_name, name)
      Flipper.send(:validate_named_instance_name!, name)

      if (existing = named_configuration(name))
        yield existing if block_given?
        return existing
      end

      # A new name is only registered once its block finishes, so a block that
      # raises leaves no half-configured instance behind. No lock is held
      # while the block runs; if another thread registered the name first,
      # reopen theirs with this block so neither thread's settings are lost.
      created = NamedConfiguration.new(name)
      yield created if block_given?
      published = @named_configurations.put_if_absent(name, created) || created
      yield published if block_given? && !published.equal?(created)
      published
    end

    # Public: Returns a configured named child without creating it.
    def named_configuration(name)
      # Stored names are already normalized, so a Symbol hit needs no checks.
      # This is on the path of every Flipper.<name> call.
      if name.is_a?(Symbol)
        found = @named_configurations[name]
        return found if found
      end

      @named_configurations[Flipper.send(:normalize_named_instance_name, name)]
    end

    # Public: Returns the configured named instance names.
    def named_instance_names
      @named_configurations.keys
    end

    # Public: Returns the configured named configurations.
    def named_configurations
      @named_configurations.values
    end

    def statsd
      require 'flipper/instrumentation/statsd_subscriber'
      Flipper::Instrumentation::StatsdSubscriber.client
    end

    def statsd=(client)
      require "flipper/instrumentation/statsd"
      Flipper::Instrumentation::StatsdSubscriber.client = client
    end

    private

    # Internal: Called after the adapter, adapter stack or default changes.
    # NamedConfiguration uses it to invalidate cached instances.
    def changed!
    end
  end
end
