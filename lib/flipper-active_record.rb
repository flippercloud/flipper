require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  require 'flipper/adapters/active_record'

  Flipper.configure do |config|
    config.adapter { Flipper::Adapters::ActiveRecord.new }
  end
end
