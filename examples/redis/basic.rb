require 'bundler/setup'
require 'logger'

require 'flipper/adapters/redis'

Flipper[:stats].enable

if Flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end

Flipper[:stats].disable

if Flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end
