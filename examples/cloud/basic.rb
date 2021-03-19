# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/basic.rb
require 'bundler/setup'
require 'flipper/cloud'
flipper = Flipper::Cloud.new

flipper[:stats].enable

if flipper[:stats].enabled?
  puts 'Enabled!'
else
  puts 'Disabled!'
end

flipper[:stats].disable

if flipper[:stats].enabled?
  puts 'Enabled!'
else
  puts 'Disabled!'
end
