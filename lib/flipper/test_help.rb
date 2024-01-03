module Flipper
  module TestHelp
    extend self

    def before_all
      Flipper.configure do |config|
        config.adapter { Flipper::Adapters::Memory.new }
        config.default { Flipper.new(config.adapter) }
      end
    end

    def before_each
      Flipper.instance = nil # Reset previous flipper instance
    end
  end
end

if defined?(RSpec)
  RSpec.configure do |config|
    config.before(:all) { Flipper::TestHelp.before_all }
    config.before(:each) { Flipper::TestHelp.before_each }
  end
elsif defined?(ActiveSupport::TestCase)
  Flipper::TestHelp.before_all

  ActiveSupport::TestCase.setup do
    Flipper::TestHelp.before_each
  end
end
