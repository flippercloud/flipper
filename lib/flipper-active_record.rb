require 'active_support/lazy_load_hooks'

ActiveSupport.on_load(:active_record) do
  require 'flipper/adapters/active_record'

  Flipper.configure do |config|
    config.default do
      Flipper.new(Flipper::Adapters::ActiveRecord.new)
    end
  end

  ActiveRecord::Base.include Flipper::Identifier
end
