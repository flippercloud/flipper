require "flipper/cloud"

Flipper.configure do |config|
  config.default do
    Flipper::Cloud.new(local_adapter: config.adapter)
  end
end
