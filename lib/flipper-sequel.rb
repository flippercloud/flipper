require 'flipper/adapters/sequel'

Flipper.configure do |config|
  config.adapter { Flipper::Adapters::Sequel.new }
end

Sequel::Model.include Flipper::Identifier
