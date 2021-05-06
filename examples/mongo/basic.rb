require 'bundler/setup'
require 'logger'

ENV["FLIPPER_MONGO_URL"] ||= "127.0.0.1:#{ENV["MONGODB_PORT"] || 27017}"
require 'flipper/adapters/mongo'

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
