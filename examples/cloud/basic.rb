# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/basic.rb
require 'bundler/setup'
require 'flipper/cloud'

Flipper[:stats].enable

if Flipper[:stats].enabled?
  puts 'Enabled!'
else
  puts 'Disabled!'
end

Flipper[:stats].disable

if Flipper[:stats].enabled?
  puts 'Enabled!'
else
  puts 'Disabled!'
end
