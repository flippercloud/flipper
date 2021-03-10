require 'flipper/adapters/sequel'

Flipper.configure do |config|
  config.default do
    Flipper.new(Flipper::Adapters::Sequel.new)
  end
end
