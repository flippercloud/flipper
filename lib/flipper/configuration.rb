module Flipper
  class Configuration
    def initialize(options = {})
      @builder = AdapterBuilder.new { store Flipper::Adapters::Memory }
      @default = -> { Flipper.new(@builder.to_adapter) }
      @named_configurations = {}
      @named_configurations_mutex = Mutex.new
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
        @builder.store(block)
      else
        @builder.to_adapter
      end
    end

    # An adapter to use to augment the primary storage adapter. See `AdapterBuilder#use`
    if RUBY_VERSION >= '3.0'
      def use(klass, *args, **kwargs, &block)
        @builder.use(klass, *args, **kwargs, &block)
      end
    else
      def use(klass, *args, &block)
        @builder.use(klass, *args, &block)
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
      else
        @default.call
      end
    end

    # Public: Configure a named Flipper instance.
    #
    # name - Lowercase snake-case name used by Flipper.named and the generated
    #        convenience method (for example, Flipper.cross_app).
    # block - Configuration block yielded a Flipper::NamedConfiguration.
    #
    # Returns the newly created named configuration.
    def named(name)
      name = Flipper.send(:normalize_named_instance_name, name)
      Flipper.send(:validate_named_instance_name!, name)

      named_configuration = @named_configurations_mutex.synchronize do
        if @named_configurations.key?(name)
          raise DuplicateNamedInstance, "Named instance #{name.inspect} has already been configured"
        end

        @named_configurations[name] = NamedConfiguration.new(name)
      end

      if block_given?
        begin
          yield named_configuration
        rescue
          @named_configurations_mutex.synchronize do
            @named_configurations.delete(name) if @named_configurations[name].equal?(named_configuration)
          end
          raise
        end
      end
      named_configuration
    end

    # Public: Returns a configured named child without creating it.
    def named_configuration(name)
      name = Flipper.send(:normalize_named_instance_name, name)
      @named_configurations_mutex.synchronize { @named_configurations[name] }
    end

    # Public: Returns the configured named instance names.
    def named_instance_names
      @named_configurations_mutex.synchronize { @named_configurations.keys.dup }
    end

    def statsd
      require 'flipper/instrumentation/statsd_subscriber'
      Flipper::Instrumentation::StatsdSubscriber.client
    end

    def statsd=(client)
      require "flipper/instrumentation/statsd"
      Flipper::Instrumentation::StatsdSubscriber.client = client
    end
  end
end
