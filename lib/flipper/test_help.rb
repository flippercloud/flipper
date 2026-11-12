module Flipper
  module TestHelp
    extend self

    def flipper_configure
      # Use a shared Memory adapter for all tests. This is instantiated outside of the
      # `configure` block so the same instance is returned in new threads.
      adapter = Flipper::Adapters::Memory.new

      Flipper.configure do |config|
        config.adapter { adapter }
        config.default { Flipper.new(config.adapter) }
        flipper_configure_named_instances(config)
      end
    end

    def flipper_configure_named_instances(config = Flipper.configuration)
      named_configurations = prune_named_test_adapters(config)
      named_configurations.each { |named| install_named_test_adapter(named) }
    end

    def flipper_reset
      # Remove all features
      Flipper.features.each(&:remove) rescue nil

      prune_named_test_adapters(Flipper.configuration).each do |named|
        test_adapter = named_test_adapters[named]
        if test_adapter && test_adapter[:version] == named.version
          Flipper.named(named.name).features.each(&:remove) rescue nil
        else
          # The named configuration changed since we installed the test
          # adapter (or we never did), so clean up and install a fresh one.
          Flipper.new(test_adapter[:adapter]).features.each(&:remove) if test_adapter
          install_named_test_adapter(named)
        end
      end

      # Reset previous DSL instance
      Flipper.instance = nil
      Flipper.send(:reset_named_instances)
    end

    private

    def named_test_adapters
      @named_test_adapters ||= {}
    end

    # Forget test adapters for named configurations that no longer exist and
    # return the current ones.
    def prune_named_test_adapters(config)
      named_configurations = Flipper.send(:named_configurations, config)
      named_test_adapters.select! { |named, _| named_configurations.include?(named) }
      named_configurations
    end

    def install_named_test_adapter(named)
      named_adapter = Flipper::Adapters::Memory.new
      named.adapter { named_adapter }
      named.default { Flipper.new(named.adapter) }
      named_test_adapters[named] = {
        adapter: named_adapter,
        version: named.version,
      }
    end
  end
end

if defined?(RSpec) && RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include Flipper::TestHelp
    config.before(:suite) { Flipper::TestHelp.flipper_configure }
    config.before(:each) { flipper_reset }
  end
end
if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_support_test_case) do
    Flipper::TestHelp.flipper_configure

    ActiveSupport::TestCase.class_eval do
      include Flipper::TestHelp

      setup :flipper_reset
    end
  end
end
