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
      return unless config.respond_to?(:named_instance_names)

      named_configurations = config.named_instance_names.map do |name|
        config.named_configuration(name)
      end
      named_test_adapters.select! { |named, _| named_configurations.include?(named) }

      named_configurations.each do |named|
        named_adapter = Flipper::Adapters::Memory.new
        named.adapter { named_adapter }
        named.default { Flipper.new(named.adapter) }
        named_test_adapters[named] = {
          adapter: named_adapter,
          version: named.version,
        }
      end
    end

    def flipper_reset
      # Remove all features
      Flipper.features.each(&:remove) rescue nil

      if Flipper.configuration.respond_to?(:named_instance_names)
        named_configurations = Flipper.configuration.named_instance_names.map do |name|
          Flipper.configuration.named_configuration(name)
        end
        named_test_adapters.select! { |named, _| named_configurations.include?(named) }

        named_configurations.each do |named|
          test_adapter = named_test_adapters[named]
          if test_adapter && test_adapter[:version] == named.version
            Flipper.named(named.name).features.each(&:remove) rescue nil
          elsif test_adapter
            Flipper.new(test_adapter[:adapter]).features.each(&:remove)
          end

          if !test_adapter || test_adapter[:version] != named.version
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

      # Reset previous DSL instance
      Flipper.instance = nil
      Flipper.send(:reset_named_instances)
    end

    private

    def named_test_adapters
      @named_test_adapters ||= {}
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
