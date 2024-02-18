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
      end
    end

    def flipper_reset
      # Remove all features
      Flipper.features.each(&:remove) rescue nil

      # Reset previous DSL instance
      Flipper.instance = nil
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
