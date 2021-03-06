# Usage (from the repo root):
#   env FLIPPER_CLOUD_TOKEN=<token> FLIPPER_CLOUD_SYNC_SECRET=<secret> FLIPPER_CLOUD_SYNC_METHOD=webhook bundle exec rackup examples/cloud/app.ru -p 9999
#   env FLIPPER_CLOUD_TOKEN=<token> FLIPPER_CLOUD_SYNC_SECRET=<secret> FLIPPER_CLOUD_SYNC_METHOD=webhook bundle exec shotgun examples/cloud/app.ru -p 9999
#   http://localhost:9999/

require 'pathname'
root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)

require 'flipper/cloud'
Flipper.configure do |config|
  config.default { Flipper::Cloud.new }
end

run Flipper::Cloud.app
