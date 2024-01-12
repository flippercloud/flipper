module Flipper
  module TestHelp
    def flipper_configure
      # Create a single shared memory adapter instance for each test
      @flipper_adapter = Flipper::Adapters::Memory.new

      Flipper.configure do |config|
        config.adapter { @flipper_adapter }
        config.default { Flipper.new(config.adapter) }
      end
    end

    def flipper_reset
      Flipper.instance = nil # Reset previous flipper instance
    end
  end
end

if defined?(RSpec) && RSpec.methods.include?(:configure)
  RSpec.configure do |config|
    config.include Flipper::TestHelp
    config.before(:all) { flipper_configure }
    config.before(:each) { flipper_reset }
  end
end

if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_support_test_case) do
    ActiveSupport::TestCase.class_eval do
      include Flipper::TestHelp

      setup :flipper_configure
      setup :flipper_reset
    end
  end
end
